require 'json'
require 'nokogiri'
require 'uri'
require 'addressable/uri'

base = 'https://yorve.github.io/secnotes'
root = File.expand_path('../_site', __dir__)
index = JSON.parse(File.read(File.join(root, 'search.json')))
abort 'Empty search index' if index.empty?

def page_at(root, url)
  path = URI::DEFAULT_PARSER.unescape(Addressable::URI.parse(url).path.sub(%r{\A/secnotes/?}, ''))
  file = File.join(root, path)
  file = File.join(file, 'index.html') if File.directory?(file)
  file += '.html' unless File.exist?(file)
  abort "Missing page: #{url}" unless File.file?(file)
  Nokogiri::HTML(File.read(file))
end

core_urls = ['/', '/articulos/', '/empieza-aqui/', '/temas/linux/', '/temas/windows/', '/temas/pentesting-web/', '/metasploitable2', '/about', '/cheatsheet/']
core_urls.each do |url|
  doc = page_at(root, base + url)
  abort "Missing title: #{url}" if doc.at_css('title')&.text.to_s.empty?
  abort "Missing description: #{url}" if doc.at_css('meta[name="description"]')&.[]('content').to_s.empty?
  abort "Missing canonical: #{url}" unless doc.at_css('link[rel="canonical"]')&.[]('href').to_s.start_with?(base)
  abort "Missing sharing image: #{url}" unless doc.at_css('meta[property="og:image"]')&.[]('content').to_s.start_with?(base)
  doc.css('script[type="application/ld+json"]').each { |script| JSON.parse(script.text) }
end

archive = page_at(root, base + '/articulos/')
archive_links = archive.css('.archive-list a').map { |a| a['href'] }
descriptions = []
index.each do |post|
  abort "Article absent from archive: #{post['url']}" unless archive_links.include?(post['url'])
  doc = page_at(root, base + post['url'].delete_prefix('/secnotes'))
  canonical = doc.at_css('link[rel="canonical"]')&.[]('href')
  abort "Incorrect canonical: #{post['url']}" unless canonical == base + post['url'].delete_prefix('/secnotes')
  summary = doc.at_css('meta[name="description"]')&.[]('content').to_s
  abort "Empty article description: #{post['url']}" if summary.strip.empty?
  descriptions << summary
  graphs = doc.css('script[type="application/ld+json"]').flat_map { |script| data = JSON.parse(script.text); data['@graph'] || [data] }
  article = graphs.find { |item| item['@type'] == 'BlogPosting' }
  abort "Missing BlogPosting schema: #{post['url']}" unless article && article['author']['url'] && article['datePublished']
  abort "Missing breadcrumbs: #{post['url']}" unless graphs.any? { |item| item['@type'] == 'BreadcrumbList' }
  abort "Missing sharing links: #{post['url']}" unless doc.at_css('.share-links a[href^="https://www.linkedin.com/"]')
end

abort 'Repeated article descriptions' unless descriptions.uniq.length == descriptions.length
['/temas/linux/', '/temas/windows/', '/temas/pentesting-web/'].each do |url|
  abort "Empty topic: #{url}" if page_at(root, base + url).css('.archive-list a').empty?
end
abort 'Missing social image' unless File.file?(File.join(root, 'assets/img/secnotes-social.png'))
sitemap = Nokogiri::XML(File.read(File.join(root, 'sitemap.xml')))
abort 'Archive missing from sitemap' unless sitemap.to_xml.include?(base + '/articulos/')
puts "Validated #{index.length} articles, unique descriptions, structured data, archive, topics and sharing metadata."
