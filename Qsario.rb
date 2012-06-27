require 'sinatra'
require 'haml'
require 'sass'
require 'digest'
require 'base64'
require 'fileutils'
require 'redis'
#require 'awesome_print'

set :views, :sass => 'views/sass', :haml => 'views/haml', :default => 'views'

configure do
  if (ENV["REDISTOGO_URL"])
    uri = URI.parse(ENV["REDISTOGO_URL"])
    REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  else
    REDIS = Redis.new
  end
end

helpers do
  def find_template(views, name, engine, &block)
    _, folder = views.detect(views[:default]) { |k,v| engine == Tilt[k] }
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
  sass style.to_sym
end

post '/upload' do
  unless params[:file] && 
      (tempfile = params[:file][:tempfile]) && 
      (name = params[:file][:filename])
    halt 400, 'You must choose a file to upload.'
  end

  # This gives us a short, URL-safe string and gives us free deduplication
  # Later, we can also ban hashes of known-bad files, etc.
  file_hash = Base64.urlsafe_encode64(Digest::SHA1.file(tempfile.path).digest).sub("=","")
  filename = "./uploads/#{file_hash}"
  REDIS.set file_hash, name  # Save original filename

  # TODO:  Check if file already existed, etc.
  FileUtils.mv(tempfile.path, filename)
  FileUtils.chmod(0400, filename)
  redirect to('/view/#{file_hash}')
end

get '/view/:file' do
  unless /\A[A-Za-z0-9_-]+\z/.match(params[:file])
    halt 400, "Invalid filename.  That doesn't look like base64 to me!"
  end

  if File.exists?("./uploads/#{params[:file]}")
    halt 200, "I have your file.  You can download it <a href='/download/#{params[:file]}'>here</a>!"
  else
    halt 404, 'File not found.'
  end
end

get '/download/:file' do
  # This makes sure that a valid file is being requested and that no one
  # can do anything sneaky.  We permit only valid Base64URL chars and we
  # already got rid of any '=' chars from padding.

  halt 404 unless /\A[A-Za-z0-9_-]+\z/.match(params[:file])

  # Keeping this test separate until I know there's nothing bad in there.
  halt 404 unless File.exists?("./uploads/#{params[:file]}")
  
  # Set filename back to the original
  attachment (REDIS.get params[:file])
  send_file "./uploads/#{params[:file]}"  # TODO:  set :type
end

# Just an example download route / easter egg.  Have a kitten!
get '/kitten' do
  attachment "kitty_cat.jpg"
  send_file './public/images/kitten.jpg', :type => :jpg
end

