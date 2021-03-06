require 'pony'
require './lib/models/hours'
require './lib/models/programs'
require './lib/models/contact_us'
require './lib/models/photos'
require './lib/models/users'

class ClyffordStillsApp < Sinatra::Base

  set :public, 'lib/public'
  enable :sessions

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html
    def current_user
      @current_user ||= Database::Users.get(session[:user_id]) if session[:user_id]
    end
  end

  get '/' do
    erb :index
  end

  get '/museum' do
    erb :museum
  end

  get '/collection' do
    erb :collection
  end

  get '/building' do
    erb :building
  end

  get '/hours' do
    if Database::Hours.db_connection.table_exists?(:hours)
      days = Database::Hours.db_connection.from(:hours)
    else
      days = []
    end
    erb :hours, locals: {days: days}
  end

  get '/directions' do
    erb :directions
  end

  get '/clyfford-still' do
    erb :clyfford_still
  end

  get '/programs' do
    programs = Database::Programs.all
    erb :programs, locals: {programs: programs}
  end

  get '/photo-gallery' do
    photos = Database::Photos.all
    erb :photo_gallery, locals: {photos: photos}
  end

  # ADMIN ROUTES
  get '/admin/hours' do
    erb :admin_hours
  end

  post '/admin/hours' do
    Database::Hours.update(params[:day], params[:opens_at], params[:closes_at])
    redirect '/admin/hours'
  end

  get '/admin/programs' do
    erb :admin_programs
  end

  post '/admin/programs' do
    successful = Database::Programs.insert(params[:program])
    if successful
      redirect '/admin/programs'      
    else
      redirect '/admin/programs-error'
    end
  end

  get '/admin/programs-error' do
    erb :admin_programs_error
  end

  get '/contact-us' do
    erb :contact_us
  end

  post '/contact-us' do
    Database::Contact.insert(params[:user])
    Pony.mail :to => params[:user][:email],
              :from => 'me@example.com',
              :subject => 'Thanks for contacting us!',
              :body => erb(:email, locals: {user: params[:user]})
    Pony.mail :to => "navyosu@gmail.com",
              :from => params[:user][:email],
              :subject => "Issue Reported from #{params[:user][:name]}",
              :body => params[:user][:issue]
    redirect '/thank-you'
  end

  get '/thank-you' do
    erb :thank_you
  end

  get '/admin/photo-gallery' do
    erb :admin_photos
  end

  post '/admin/photo-gallery' do
    Database::Photos.create({filename: params['new_file'][:filename]})
    File.open('lib/public/uploads/' + params['new_file'][:filename], 'w') do |f|
      f.write(params['new_file'][:tempfile].read)
    end
    redirect '/admin/photo-gallery'
  end

end
