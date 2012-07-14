REQS = %w(awesome_print base64 digest fileutils haml redis salty sass sequel sinatra)
REQS.each { |r| require r }

configure do
  set :views, :sass => 'views/sass', :haml => 'views/haml', :default => 'views'
  use Rack::Session::Cookie,  :key => 'Qsario_Session',
			      :expire_after => 60*60*24,
			      :secret => ENV['COOKIE_SECRET']
  uri = URI.parse(ENV["REDISTOGO_URL"])
  REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  Sequel.connect(ENV['DATABASE_URL'] || 'postgres://localhost/Qsario')
end

MODELS = %w(User Upload)
MODELS.each { |m| require './models/'+m }

helpers do
  def find_template(views, name, engine, &block)
    _, folder = views.detect(views[:default]) { |k,v| engine == Tilt[k] }
    super(folder, name, engine, &block)
  end

  def error_page(opt = {})
    @error_code	    = response.status.to_s
    @error_title    = opt[:title]   || ("Error " + @error_code)
    @error_message  = opt[:message] || "Something blew up.  Who let a creeper in?"
    halt haml :error
  end

  def md5_to_slug(md5)
    # We base64 encode our hashes, then remove the padding (the '=' at the end)
    # to make them shorter.
    Base64.urlsafe_encode64(md5).gsub("=", "")
  end

  def valid_slug?(slug)
    # An MD5, once base64ed and with the padding removed is exactly 22 chars long.
    !!/\A[A-Za-z0-9_-]{22}\z/.match(slug)
  end
end

get '/me' do
  puts User.first.awesome_inspect
  puts User.first.uploads.awesome_inspect
  User.first.uploads.to_s
end

get '/' do
  haml :index
end

get '/:page/?' do |p|
  pages = %w(contact legal)
  pass unless pages.index(p) 
  haml p.to_sym
end

get '/register/?' do
  @no_login_form = true	  # Hide the form in the header
  haml :register
end

post '/login/?' do
  ap params
  redirect to('/')
end

not_found do
  error_page(title: "Page Not Found", message: "We couldn't find " + request.path_info.to_s)
end

error 400..403, 405..599 do
  error_page
end

# CSS is no longer sassed on demand.  Static, compressed versions have been generated
# and put in public/css.

post '/upload/?' do
  unless params[:file] && 
      (tempfile = params[:file][:tempfile]) && 
      (name = params[:file][:filename])
    status 400
    error_page(title: "No File Selected", message: "You must choose a file to upload.")
  end

  # This gives us a short, URL-safe string and gives us free deduplication
  # Later, we can also ban hashes of known-bad files, etc.
  file_hash = md5_to_slug(Digest::MD5.file(tempfile.path).digest)
  filename = "./uploads/#{file_hash}"
  REDIS.set file_hash, name  # Save original filename

  # TODO:  Check if file already existed, etc.
  FileUtils.cp(tempfile.path, filename)
  FileUtils.chmod(0400, filename)
  redirect to("/view/#{file_hash}")
end

get '/view/:file' do
  unless valid_slug?(params[:file])
    # Error 400 tells the client they should quit asking.
    status 400
    error_page(title: "No Such File", message: "We don't have a file like that.")
  end

  if File.exists?("./uploads/#{params[:file]}")
    halt 200, "I have your file.  You can download it <a href='/download/#{params[:file]}'>here</a>!"
  else
    halt 404
  end
end

get '/download/:file' do
  # This makes sure that a valid file is being requested and that no one
  # can do anything sneaky.  We permit only valid Base64URL chars and we
  # already got rid of any '=' chars from padding.

  halt 404 unless valid_slug?(params[:file])

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

