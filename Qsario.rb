REQS = %w(awesome_print aws/s3 base64 digest fileutils haml json openssl 
	  redis salty sass securerandom sequel sinatra virus_blacklist)
REQS.each { |r| require r }

configure do
  set :views, :sass => 'views/sass', :haml => 'views/haml', :default => 'views'
  use Rack::Session::Cookie,  :key => 'rack.session',
			      :expire_after => 60*60*24,
			      :secret => ENV['COOKIE_SECRET']
  REDIS = Redis.connect(:url => ENV["REDISTOGO_URL"])
  Sequel.connect(ENV['HEROKU_POSTGRESQL_GOLD_URL'] || 'postgres://localhost/Qsario')
  Dir["./models/*.rb"].each { |model| require model }
end

helpers do
  def find_template(views, name, engine, &block)
    ignored, folder = views.detect(views[:default]) { |k,v| engine == Tilt[k] }
    super(folder, name, engine, &block)
  end

  def aws_encode(text)	# This is how I have to encode my policy & signature for AWS.
    Base64.encode64(text).gsub("\n","")
  end

  def aws_signature(policy) # Generates a signature when given a policy.
    aws_encode(
      OpenSSL::HMAC.digest(
	OpenSSL::Digest::Digest.new('sha1'), 
	ENV['AWS_SECRET_ACCESS_KEY'], 
	aws_encode(policy)))
  end

  def error_page(opt = {})  # Helps make nice error pages.
    @error_code	    = response.status.to_s
    @error_title    = opt[:title]   || ("Error " + @error_code)
    @error_message  = opt[:message] || "Something blew up.  Who let a creeper in?"
    halt haml :error
  end

  def md5_to_slug(md5)	    # Makes MD5s into short, URL-safe strings.
    return Base64.urlsafe_encode64(md5).gsub("=", "")  
  end

  def valid_slug?(slug)	    # Checks if it looks like something from md5_to_slug. 
    return !!/\A[A-Za-z0-9_-]{22}\z/.match(slug)  # Return booleans, not matchdata. 
  end

  def logged_in?
    REDIS.exists ("user:" + session[:id])
  end

  def must_login!	    # Forces users to log in if they haven't. 
    redirect to("/login") unless logged_in? 
  end
end

before do   # Gives everyone a session ID to identify them.
  session[:id] ||= SecureRandom.uuid
end

get '/' do
  haml :index
end

post '/test' do
  ap params  # Debug route for seeing what params we actually get.  Only works from command line anyhow.
end

get '/:page/?' do |p|
  pages = %w(contact legal)
  pass unless pages.find(p) 
  haml p.to_sym
end

get '/register/?' do
  error_page(title: "Already Registered", message: "You do not need to register.  You are already registered.") if logged_in?
  haml :register
end

post '/register/?' do
  error_page(title: "Already Registered", message: "You are already registered.") if logged_in?
  redirect to('/')
end

post '/login/?' do
  @user = User.find(:name => params[:name])
  if @user && Salty.check(params[:password], @user.values[:password])
    @key = "user:" + session[:id]
    REDIS.set @key, @user.to_json
    REDIS.expire @key, 60*60*24    # One day from now.
  else
    error_page(title: "Login Failed", message: "Your username or password was incorrect.")
  end
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
  must_login!
  unless params[:file] &&  # TODO: Fix - files will go to S3. 
      (tempfile = params[:file][:tempfile]) && 
      (name = params[:file][:filename])
    status 400
    error_page(title: "No File Selected", message: "Please choose a file to upload.")
  end

  # This gives us a short, URL-safe string and gives us free deduplication
  # Later, we can also ban hashes of known-bad files, etc.
  md5 = Digest::MD5.file(tempfile.path).digest
  file_hash = md5_to_slug(md5)
  filename = "./uploads/#{file_hash}"
  REDIS.set file_hash, name  # Save original filename

  # TODO:  Check if file already existed, etc.
  FileUtils.cp(tempfile.path, filename)
  FileUtils.chmod(0400, filename)
  redirect to("/view/#{file_hash}")
end

get '/view/:file' do
  unless valid_slug?(params[:file])
    status 400  # Sure, nothing was found, but we want them to stop asking.  This can't be a real file, so 
		# this request will never return useful content.  Someone mangled the slug, so it doesn't
		# refer to anything.
    error_page(title: "No Such File", message: "We don't have a file like that.")
  end

  if File.exists?("./uploads/#{params[:file]}")
    # The 200 is an HTTP status code.  TODO:  Make this a nice page, not just an ugly blob of text.
    halt 200, "I have your file.  You can download it <a href='/download/#{params[:file]}'>here</a>!"
  else
    status 404 # TODO Make a nicer 404 not found page.
    error_page(title: "No Such File", message: "We don't have a file like that.")
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

