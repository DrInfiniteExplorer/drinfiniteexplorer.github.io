
import pathlib
import copy

import jinja2
import markdown
import frontmatter
import yaml

jinja = jinja2.Environment(
    loader=jinja2.FileSystemLoader('templates')
)



def load_config():
    with open("Stuff/config.yml") as f:
        return yaml.safe_load(f)

def enum_crap():
    return pathlib.Path('Stuff').glob('./**/*.md')

def read_frontmatter(pathy):
    return frontmatter.load(pathy.as_posix())


def load_post(post_path, config):
    print(post_path.as_posix())

    post = read_frontmatter(post_path)
    post['raw'] = post.content

    stem = post_path.stem
    dest_path = f"{post_path.stem}.html"
    url = dest_path
    default_settings = dict(
        stem = stem,
        dest_path = dest_path,
        url = url,
    )

    metadata = {}
    metadata.update(default_settings)
    metadata.update(post.metadata)
    post.metadata = metadata

    metadata.update(orig_file_path = post_path)

    return post

def link_posts(posts, config):

    category_names = list({p['category'] for p in posts if 'category' in p})

    categories = { name:[post for post in posts if post.get('category', None) == name] for name in category_names}

    print(categories)

    for name, catlist in categories.items():
        for idx, post in enumerate(catlist):
            prev, next = None, None

            if idx > 0:
                prev = catlist[idx-1]
            if idx + 1 < len(catlist):
                next = catlist[idx+1]
            post['cat_prev_post'] = prev
            post['cat_next_post'] = next

    for idx, post in enumerate(posts):
        prev, next = None, None

        if idx > 0:
            prev = posts[idx-1]
        if idx + 1 < len(posts):
            next = posts[idx+1]
        post['prev_post'] = prev
        post['next_post'] = next
    
    config.update(categories = categories)



def preprocess_post(post, config):

    downed = render_markdown(post.content, configs=[config, post])
    post.content = downed

    return post

def merge_conf(configs, config_key):
    conf = {}
    for config in configs:
        the_thing = config.get(config_key, {})
        conf.update(the_thing)

        for key, value in list(conf.items()):
            if not key.startswith("+"):
                continue
            target = key[1:]
            if isinstance(value, list):
                lst = copy.deepcopy(conf.get(target, []))
                lst += value
                conf[target] = lst
            elif isinstance(value, dict):
                dct = copy.deepcopy(conf.get(target, {}))
                dct.update(value)
                conf[target] = dct
            else:
                raise RuntimeError("Arr lmao error yo")
            del conf[key]
    return conf
    

def render_markdown(stuff, configs):
    md_conf = merge_conf(configs, 'markdown')

    print(md_conf)
    md = markdown.Markdown(**md_conf)
    return md.convert(stuff)

def render_jinja(post, config):
    assert "layout" in post, f"post {post['orig_file_path'].as_posix()} is missing layout setting"
    template = jinja.get_template(f"{post['layout']}.html")
    rendered = template.render(post = post, yolo = "yeet", **config)
    return rendered
    

def process(post, config):

    stuff = render_jinja(post, config)
    post['rendered'] = stuff
    return post

def write_output(post):

    out_path = pathlib.Path(f"docs/{post['dest_path']}")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(post['rendered'], encoding='utf8')

    return post

def copy_statics(posts):
    out_root = pathlib.Path("docs")
    for post in posts:
        static_root = post['orig_file_path'].parent / "static"
        print(f"Globbing in {static_root.as_posix()}")

        for file in static_root.glob('**/*'):
            relative_path = file.relative_to(static_root).as_posix()
            out_path = out_root / relative_path

            print(f"Copying {file.as_posix()} to {out_path.as_posix()}")

            out_path.parent.mkdir(parents=True, exist_ok=True)
            assert not out_path.exists()
            out_path.write_bytes(file.read_bytes())


def main():
    print("\n" * 5)
    print("Starting Generation!")
    print("\n" * 3)

    import shutil
    shutil.rmtree('docs', ignore_errors=True)

    config = load_config()

    posts = [load_post(post, config) for post in enum_crap()]

    link_posts(posts, config)

    config['posts'] = posts

    for post in posts: preprocess_post(post, config)

    posts = [process(post, config) for post in posts]

    for post in posts: write_output(post)

    copy_statics(posts)




if __name__ == '__main__':
    main()