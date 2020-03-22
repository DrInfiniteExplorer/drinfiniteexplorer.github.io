# https://stackoverflow.com/a/25802375
module Jekyll
  module ExtractLinks
    def extract_href(input)
    # https://stackoverflow.com/a/15926317
      #re = Regexp.new "<a\s+(?:[^>]*?\s+)?href=(["'])(.*?)\1"
      
      asd = input.scan(/<a\s+(?:[^>]*?\s+)?href=(["'])(.*?)\1[^>]*>([^<]*)</).map { |x| { 'url' => x[1], 'text' => x[2]} }
      
      print(asd)
      asd
      
      # This will be returned
      #input.gsub re, repl_str
    end
  end
end

Liquid::Template.register_filter(Jekyll::ExtractLinks)