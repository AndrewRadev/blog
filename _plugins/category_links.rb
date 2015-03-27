# TODO (2015-03-27) Not used at this time. Turns out actually generating
# category pages requires actual effort.
#
module Jekyll
  module CategoryLinks
    def category_links(categories)
      categories.map do |c|
        %Q{<a href="/categories/#{c}">#{c}</a>}
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::CategoryLinks)
