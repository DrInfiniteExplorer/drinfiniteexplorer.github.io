
require "gemoji"

module Hacky

  class EmojiHack < Jekyll::Generator
    def generate(site)

      if !site.config.fetch("emoji", true)
        return
      end

      additional_keys = site.config.fetch("emoji-additional-keys", [])

      get_images_path(site)

      site.pages.each { |p| substitute(p, additional_keys) }

      (site.posts.respond_to?(:docs) ? site.posts.docs : site.posts ).each { |p| substitute(p, additional_keys) }
    end


    def get_images_path(site)
      @images_path = {}
      if site.config["emoji-images-path"]

        images_path = site.config["emoji-images-path"]
        images_dir  = File.join(site.source, images_path)
        Dir.foreach(images_dir) do |image_filename|
          if /^(?<tag>.*)\.(?:svg|png|jpg|jpeg|gif)/ =~ image_filename
            @master_whitelist << tag
            @images_path[tag] = File.join("/", images_path, image_filename)
          end
        end

      end
    end
    
    def match_image(name, custom)
      for entry in custom do
        prefix = entry['prefix'] || ''
        if name.start_with?(prefix)
            local_name = name.delete_prefix(prefix)
            assets=entry['assets']
            Dir.foreach(assets) do |image_filename|
              if /^(?<tag>.*)\.(?:svg|png|jpg|jpeg|gif)/ =~ image_filename && image_filename.start_with?(local_name + '.')
                img_src = '/' + assets + '/' +  image_filename
                return img_src
              end
            end
        end
      end
      nil
    end

    def substitute(obj, additional_keys)
      settings= obj.data.fetch('custom_emoji', {})
      custom_list = settings.fetch('sources',[])
      
      
      if !obj.data.fetch("emoji", true)
        return
      end
      
      if settings.fetch('zwj-merge',false)
          # Ruby is retarded and can't do nested/repeating capture groups which makes me sad.
          # And I don't want to delve further into the profanities of regex state machines
          # The code ends up being 100% better with double gsub.
          # outer patter: A(,A)+ but A is :\w\ and , is zero-width-joiner.
          obj.content.gsub!(/:([\w\+\-]+):(\u200d:([\w\+\-]+):)+/) do |s|
            
            stuff = []
            raw=[]
            asd = s.gsub(/:([\w\+\-]+):/) do |m|
              raw.append($1)
              stuff.append(match_image($1, custom_list))
            end
            background_images=[]
            background_sizes=[]
            for elem in 0..stuff.length()-2 do
              background_images.append("url(#{stuff[elem]})")
              background_sizes.append("32px 32px")
            end
            style = 'style="' + "background-image: #{background_images.join(', ')}; background-size: #{background_sizes.join(', ')}" + '"'
            asd = convert(raw[-1], custom_list, style)
            
            asd
          end
      end


#      obj.content.gsub!(/:([\w\+\-]+):‍/) do |s|
      obj.content.gsub!(/:([\w\+\-]+):/) do |s|
        convert($1, custom_list)
      end

      additional_keys.each do |key|
        if obj.data.has_key?(key)
          obj.data[key].gsub!(/:([\w\+\-]+):‍/) do |s|
            convert($1)
          end
        end
      end
    end

    # convert takes in the key to the emoji to be converted and an optional block
    # If block is provided, conversion will be done only if this block evaluates to true.
    def convert(key, custom, css = '')
      if true
        img_tag(key, custom, css)
      else
        ":#{key}:"
      end
    end

    def img_tag(name, custom, css)
      # if there is an image in the custom images path
      img_src = match_image(name, custom)
      
      if !img_src
        if @images_path[name]
          img_src = @images_path[name]
        else # otherwise use fallback CDN
          img_src = "https://github.githubassets.com/images/icons/emoji/#{name}.png"
        end
      end
      
      "<img class='emoji' title='#{name}' alt='#{name}' src='#{img_src}' height='32' width='32' align='absmiddle' #{css}>"
    end
  end
end





#module Hacky
#    module EmojiTranslation
#      def hack(content)
#        print(content)
#        h(content).to_str.gsub(/:([\w+-]+):/) do |match|
#          if emoji = Emoji.find_by_alias($1)
#            %(<img alt="#$1" src="#{"emoji/#{emoji.image_filename}"}" style="vertical-align:middle" width="20" height="20" />)
#          else
#            match
#          end
#        end#.html_safe if content.present?
#      end
#    end
#end

# require "jekyll"
# require "html/pipeline"

# module Jekyll
  # class Emoji
    # GITHUB_DOT_COM_ASSET_HOST_URL = "https://github.githubassets.com"
    # ASSET_PATH = "/images/icons/"
    # BODY_START_TAG = "<body"
    # OPENING_BODY_TAG_REGEX = %r!<body(.*?)>\s*!m.freeze

    # class << self
      # def emojify(doc)
        # return unless doc.output&.match?(HTML::Pipeline::EmojiFilter.emoji_pattern)

        # doc.output = if doc.output.include? BODY_START_TAG
                       # replace_document_body(doc)
                     # else
                       # src = emoji_src(doc.site.config)
                       # filter_with_emoji(src).call(doc.output)[:output].to_s
                     # end
      # end

      # # Public: Create or fetch the filter for the given {{src}} asset root.
      # #
      # # src - the asset root URL (e.g. https://github.githubassets.com/images/icons/)
      # #
      # # Returns an HTML::Pipeline instance for the given asset root.
      # def filter_with_emoji(src)
        # filters[src] ||= HTML::Pipeline.new([
          # HTML::Pipeline::EmojiFilter,
        # ], :asset_root => src, :img_attrs => { :align => nil }, :asset_path => "")
      # end

      # # Public: Filters hash where the key is the asset root source.
      # # Effectively a cache.
      # def filters
        # @filters ||= {}
      # end

      # # Public: Calculate the asset root source for the given config.
      # # The custom emoji asset root can be defined in the config as
      # # emoji.src, and must be a valid URL (i.e. it must include a
      # # protocol and valid domain)
      # #
      # # config - the hash-like configuration of the document's site
      # #
      # # Returns a full URL to use as the asset root URL. Defaults to the root
      # # URL for assets provided by an ASSET_HOST_URL environment variable,
      # # otherwise the root URL for emoji assets at assets-cdn.github.com.
      # def emoji_src(config = {})
        # if config.key?("emoji") && config["emoji"].key?("src")
          # config["emoji"]["src"]
        # else
          # default_asset_root
        # end
      # end

      # # Public: Defines the conditions for a document to be emojiable.
      # #
      # # doc - the Jekyll::Document or Jekyll::Page
      # #
      # # Returns true if the doc is written & is HTML.
      # def emojiable?(doc)
        # (doc.is_a?(Jekyll::Page) || doc.write?) &&
          # doc.output_ext == ".html" || (doc.permalink&.end_with?("/"))
      # end

      # private

      # def default_asset_root
        # if !ENV["ASSET_HOST_URL"].to_s.empty?
          # # Ensure that any trailing "/" is trimmed
          # asset_host_url = ENV["ASSET_HOST_URL"].chomp("/")
          # "#{asset_host_url}#{ASSET_PATH}"
        # else
          # "#{GITHUB_DOT_COM_ASSET_HOST_URL}#{ASSET_PATH}"
        # end
      # end

      # def replace_document_body(doc)
        # src                 = emoji_src(doc.site.config)
        # head, opener, tail  = doc.output.partition(OPENING_BODY_TAG_REGEX)
        # body_content, *rest = tail.partition("</body>")
        # processed_markup    = filter_with_emoji(src).call(body_content)[:output].to_s
        # String.new(head) << opener << processed_markup << rest.join
      # end
    # end
  # end
# end

# Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
  # Jekyll::Emoji.emojify(doc) if Jekyll::Emoji.emojiable?(doc)
# end