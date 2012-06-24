require 'sinatra'
require 'haml'
require 'sass'
require 'awesome_print'

set :views, :sass => 'views/sass', :haml => 'views/haml', :default => 'views'

helpers do
  def find_template(views, name, engine, &block)
    _, folder = views.detect(views[:default]) { |k,v| engine == Tilt[k] }
    #folder ||= views[:default]
    super(folder, name, engine, &block)
  end
end

get '/' do
  haml :index
end

get '/:page' do |p|
  pages = %w(contact legal register)
  pass unless pages.index(p) >= 0
  haml p.to_sym
end

get '/css/:style' do |style|
  styles = %w(colors layout)
  style = style.sub(".css", "")	# Can't use sub!() because it returns nil if no match.
  pass unless styles.index(style) >= 0
  sass style.sub(".css", "").to_sym
end

get '/kitten' do
  attachment "kitty_cat.jpg"
  send_file './public/images/kitten.jpg', :type => :jpg
end

