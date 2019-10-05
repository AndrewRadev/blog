# encoding: utf-8
#
class Jekyll::MarkdownHeader < Jekyll::Converters::Markdown
  def convert(content)
    super.gsub(/<h([12]) id="(.*?)">/, '<h\1 id="\2"><a class="anchor" aria-hidden="true" href="#\2">🔗</a>')
  end
end
