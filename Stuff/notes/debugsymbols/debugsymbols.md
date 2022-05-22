---
layout: post
title:  "Notes on debug symbols"
date:   2022-03-27 17:35 +0100

category: notes


markdown:
  +extensions:
    - sane_lists

---

Debug symbols wooh yeah!

* Enables introspection of binary executables
* Type information!
* Global symbols & address resolution
* Global methods
* Secrets the goverment doesn't want us to know 👽

### Formats?

* PDB - Produced by MS compilers, proprietary format
* DWARF - Everybody else?

### Core Ideas

```c++
struct Struct {
    Struct* StructPtr;
    int yeet[2];
    int yolo[3][2];
};
```
is (aproximately) represented in debug symbol format as (pseudocode)
```python3
Struct = {
    members: [
        ("StructPtr", StructPtrType),
        ("yeet", ArrayType1)
        ("yolo", ArrayType2)
    ]
}

StructPtrType = POINTER(Struct)

ArrayType1 = Array(2, int)
ArrayType2 = Array(3, ArrayType1)

```


#### Libraries

* dbghelper lel
* DIA sdk
* [pdbparse] on github and **pip** by Moyix. Pretty old? Requires full parse before usable? No documentation? 😭
* [roslyn] is c# implementation of _windows_ and _portable_
* [CCI] is old c# implementation
* [libpdb] is a linux(platform limited? 🤔)-lib to parse PDB files
* [pdbex] recreates struct/unions from PDB-files using *DIA*
* [willglynn/pdb] is a rust-library to lazily explore PDB files  
    Is rust always hard to follow, or is the implementation spooky?
* [microsoft-pdb] from MS is actual implementation of stuff.  
    Seriously who wrote this, I get it,-92 and stuff, but when is `mpspnpn` or `mpsnsi` ever a good variable name???? 🙂🔫



### References/Sources

* [GREAT WRITEUP](https://llvm.org/docs/PDB/index.html) at LLVM by [zjturner](https://github.com/zjturner?tab=repositories) (see [this](https://github.com/microsoft/microsoft-pdb/issues/51#issuecomment-954217478))
* [A presentation](https://llvm.org/devmtg/2016-11/Slides/Kleckner-CodeViewInLLVM.pdf), also from LLVM.

* [A twitter thread](https://twitter.com/aionescu/status/1057739095495954432) which asks for non-DIA PDB parsers
    * Moyix recommended CCI
    * Others recommend DIA
    * Some bloke recommends Roslyn
* [CCI] from Microsoft - Old code for reading/writing PDB files in c#
    * These two 👇 are linked replacements from the CCI repository
    * [Cecil](https://github.com/jbevain/cecil/tree/master/symbols)
    * [Roslyn]
* [llvm-pdbutil](https://llvm.org/docs/CommandGuide/llvm-pdbutil.html) which does work with PDB files
* [Radare2] - OSS hacking/reversing/whatever tool with PDB capabilities
* [MS_Symbol_Type_v1.0.pdf](https://pierrelib.pagesperso-orange.fr/exec_formats/MS_Symbol_Type_v1.0.pdf)

-----------

#### c# packages?

Those are a bit messy but after trying to sort things out it boils down to _"Windows PDB in Roslyn"_ and _"Portable PDB in symreader-portable"_

* [Microsoft.DiaSymReader]
    * _Project Website_ & _Source Repo_ -> [symreader]
    * [symreader]
        * Managed COM **definition** for DiaSymReader
        * Windows PDB implementation-> [Microsoft.DiaSymReader.Native]
        * Portable PDB implementation-> [Microsoft.DiaSymReader.PortablePdb]
* [Microsoft.DiaSymReader.Native]
    * _Project Website_ -> [roslyn]
* [Microsoft.DiaSymReader.PortablePdb]
    * _Project Website_ & _Source Repo_ -> [symreader-portable]
    * [symreader-portable]
        * COM interface definition -> [Microsoft.DiaSymReader]
        * **Implements** DiaSymReader interface for **Portable PDB**




#### Portable PDB

* [Portable PDB format](https://github.com/dotnet/core/blob/main/Documentation/diagnostics/portable_pdb.md) intro.

Can't find any source that explicitly says "This is CLI only and not for any native images" ¯\\_(ツ)\_/¯



### MS PDB implementation notes

* Most of the code deals with `PB` (pointer bytes) for everything. What is typing? Who knows.

* `PB` often points at a `REC` which consists of a

    `(whole_record_byte_count : u16, leaf_type : 16)` -tuple that is directly followed by type-specific data.

* The method for [extracting the name](https://github.com/microsoft/microsoft-pdb/blob/e6b1dec61e154b568357537792e1d17a13525d5d/PDB/include/symtypeutils.h#L24) from a type record calls `cbNumField` which calls `CbGetNumericData` which is lacking an implementation.
     * BUT [searching github](https://github.com/search?q=CbGetNumericData&type=code) for methods of that name gives a few interesting repos,
     like [this](https://github.com/Hengle/windows_nt_4_source_code/blob/d372619346dd27ad63524d5477f33fdaf2b8e0a4/windows_nt_4_source_code/nt4/private/sdktools/vctools/pdb/mre/mretype.cpp#L39)
     and [this](https://github.com/fungosforks/Windows-NT-4.0-Source/blob/7a9a4aa4c3f950d0cd5512af11224084205e8fc0/private/sdktools/vctools/pdb/mre/mretype.cpp#L39).
     Claims to be NT 4 source code?

* TI from name at `BOOL TPI1::QueryTiForUDT(const char *sz, BOOL fCase, OUT TI* pti)`     
* hash string:

    ```c++
    LHASH hashSz(SZ_CONST sz) const
    {
        size_t  cch = strlen(sz);
        return LHashPbCb((PB)sz, cch, hdr.tpihash.cHashBuckets);
    }
    ```
    More hashing in misc.h

* LLVM hashing
    LLVM hashes in `\llvm-project\llvm\lib\DebugInfo\PDB\Native\Hash.cpp`
    LLVM TPI hash in `llvm-project\llvm\lib\DebugInfo\PDB\Native\TpiStream.cpp` and writing in `TpiStreamBuilder.cpp`.

    Seems that UDTs (non-forward?) are hashed on name (unique or not dep on scope-flag?) using V1 hash
    FWD entries are hashed on the whole bytes for the record tho??? But then that's not used
    Seems they are also hashed on name and that's used.

    In file there's a hash for every TI, and bitfields with {valid, valid} kinda, so for every TI
    there is {hash, valid, valid}.
    Make a bucket idx from the hash by % (#buckets).
    Make a list yourself at HashLists[BucketId] and append the TI to it.
    Then to find a thing by name, make the hash, walk the list, match the LeafID, hash(?), name.

* Index&Offset:

    A plain "skip list" of {TI, offset}.
    Given a TI, "guess" where it should be in the list (like ((TI-min_ti)/TI_Count) * ListLen) and walk up/down
     until {TI, offset} is found that is as close below target TI as possible, then iterate records from that
     offset forward until found.

* CCI [field types](https://github.com/microsoft/cci/blob/master/PDBReaderAndWriter/PdbReader/CvInfo.cs)


### MS PDB implementation Glossary

* _Leaf_ - A thing that identifies a type record.
    
    Though the type record doesn't need to be a leaf in a graph/tree of the type composition.













[pdbparse]: https://github.com/moyix/pdbparse
[Roslyn]: https://github.com/dotnet/roslyn
[CCI]: https://github.com/microsoft/cci
[libpdb]: https://github.com/shareef12/libpdb
[pdbex]: https://github.com/wbenny/pdbex
[willglynn/pdb]: https://github.com/willglynn/pdb
[microsoft-pdb]: https://github.com/microsoft/microsoft-pdb

[symreader]: https://github.com/dotnet/symreader
[symreader-portable]: https://github.com/dotnet/symreader-portable

[Microsoft.DiaSymReader]: https://www.nuget.org/packages/Microsoft.DiaSymReader
[Microsoft.DiaSymReader.Native]: https://www.nuget.org/packages/Microsoft.DiaSymReader.Native
[Microsoft.DiaSymReader.PortablePdb]: https://www.nuget.org/packages/Microsoft.DiaSymReader.PortablePdb

[Radare2]: https://github.com/radareorg/radare2/tree/master/libr/bin/pdb

*[PDB]: Program Database
*[DIA]: Debug Interface Access, a COM api for reading(writin?) PDB files
*[DWARF]: Debugging With Arbitrary Record Formats (smh my head)
*[CCI]: Common Compiler Infrastrucutre
