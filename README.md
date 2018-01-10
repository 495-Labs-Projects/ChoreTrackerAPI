# Objectives

In this lab we will be creating an RESTful API version of the ChoreTracker application, which means there are no need for views (just controller and model code). There will be 4 things that will be covered in this lab:

- Creating the API itself
- Documenting the API with swagger docs
- Serialization Customizations
- Stateless authentication for the API


# Part 5 - Filtering and Ordering



# Part 6 - Token Authentication


1. Now we will tackle authentication for API's since we don't want just anyone modifying the chores (especially the children)!!! This will be slightly different from authentication for regular Rails applications mainnly because the authentication will be stateless and we will be using a token (instead of a emai and password). For this to work we will first need to create a User model! Follow the specifications below and generate a new User model and run ```rails db:migrate```. Note that there is still a email and password because we still want there to be a way later on for users to retrieve their authentication token (if they forgot it) by authentication through email and password.
    - User
        - email (string)
        - password_digest (string)
        - api_key (string)
        - active (boolean)

2. For now lets fill the User model with some validations. This is pretty standard and we have already done something similar before, so just copy paste the code below to your User model.

    ``` ruby
    class User < ApplicationRecord
      has_secure_password
    
      validates_presence_of :email
      validates_uniqueness_of :email, allow_blank: true
      validates_presence_of :password, on: :create 
      validates_presence_of :password_confirmation, on: :create 
      validates_confirmation_of :password, message: "does not match"
      validates_length_of :password, minimum: 4, message: "must be at least 4 characters long", allow_blank: true
    end
    ```

3. So the general idea of the api_key is so that when someone sends a GET/POST/etc. request to your api, they will also need to provide the token in a header. Your API will then try to authenticate with that token and see what authorization that user has. This means that the api_key needs to be unique so we will not be allowing users to change/create the api_key. Instead we will be generating a random api_key for each user when it is created. Therefore we will write a new callback function in the model code for creating the api_key. The following is the new model code. Please understand it before continuing, or else everything will be rather confusing!!!!! (Note: Don't forget to add the ```gem 'bcrypt'``` to the Gemfile for passwords).

    ```
    class User < ApplicationRecord
      has_secure_password
    
      validates_presence_of :email
      validates_uniqueness_of :email, allow_blank: true
      validates_presence_of :password, on: :create 
      validates_presence_of :password_confirmation, on: :create 
      validates_confirmation_of :password, message: "does not match"
      validates_length_of :password, minimum: 4, message: "must be at least 4 characters long", allow_blank: true
      validates_uniqueness_of :api_key
    
      before_create :generate_api_key
    
      def generate_api_key
        begin
          self.api_key = SecureRandom.hex
        end while User.exists?(api_key: self.api_key)
      end
    end
    ```

4. Now we should create the User controller and the Swagger Docs for the controller. This should be quick since you have done this already for all the other controllers. (Note: make sure that the user params method permits these parameters because we don't want them creating the api_key: params.permit(:email, :password, :password_confirmation, :role, :api_key, :active)) After you are done, verify that it is the same as below and make sure the create documentation has the right form parameters. Also add the user resources to the routes.rb and run ```rails swagger:docs```

    ```
    class UsersController < ApplicationController
      # This is to tell the gem that this controller is an API
      swagger_controller :users, "Users Management"
    
      # Each API endpoint index, show, create, etc. has to have one of these descriptions
    
      # This one is for the index action. The notes param is optional but helps describe what the index endpoint does
      swagger_api :index do
        summary "Fetches all Users"
        notes "This lists all the users"
      end
    
      # Show needs a param which is which user id to show.
      # The param defines that it is in the path, and that it is the User's ID
      # The response params here define what type of error responses can be returned back to the user from your API. In this case the error responses are 404 not_found and not_acceptable.
      swagger_api :show do
        summary "Shows one User"
        param :path, :id, :integer, :required, "User ID"
        notes "This lists details of one user"
        response :not_found
        response :not_acceptable
      end
    
      # Create doesn't take in the user id, but rather the required fields for a user (namely first_name and last_name)
      # Instead of a path param, this uses form params and defines them as required
      swagger_api :create do
        summary "Creates a new User"
        param :form, :email, :string, :required, "Email"
        param :form, :password, :password, :required, "Password"
        param :form, :password_confirmation, :password, :required, "Password Confirmation"
        param :form, :active, :boolean, :required, "active"
        response :not_acceptable
      end
    
      # Lastly destroy is just like the rest and just takes in the param path for user id. 
      swagger_api :destroy do
        summary "Deletes an existing User"
        param :path, :id, :integer, :required, "User Id"
        response :not_found
        response :not_acceptable
      end
    
    
      # Controller Code
    
      before_action :set_user, only: [:show, :update, :destroy]
    
      # GET /users
      def index
        @users = User.all
    
        render json: @users
      end
    
      # GET /users/1
      def show
        render json: @user
      end
    
      # POST /users
      def create
        @user = User.new(user_params)
    
        if @user.save
          render json: @user, status: :created, location: @user
        else
          render json: @user.errors, status: :unprocessable_entity
        end
      end
    
      # DELETE /users/1
      def destroy
        @user.destroy
      end
    
      private
        # Use callbacks to share common setup or constraints between actions.
        def set_user
          @user = User.find(params[:id])
        end
    
        # Only allow a trusted parameter "white list" through.
        def user_params
          params.permit(:email, :password, :password_confirmation, :role, :api_key, :active)
        end
    end
    ```

5. We should also create a new serializer for users since we really don't want to display the password_digest, but we do need to show the api_key. 

6. We can now start up the rails server and test out whether or not our user model creation worked! Create a new user using Swagger and **save the api_key from the response**, this is **very important** for the next steps!

7. Next we need to actually implement the authentication with the tokens so that nobody can modify anything in the system without having a proper token. You will need to add the following to the ApplicationController. This uses the built in ```authenticate_with_http_token``` method which checks if it is a valid token and if anything fails, it will just render the Bad Credentials JSON. How it works is that every request that comes through has to have an Authorization header with the specified token and that is what rails will check in order to authenticate. Also for simplicity, we authenticated for all actions in all controllers by putting a before_action in the ApplicationController.

    ```ruby
    class ApplicationController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods
    
      before_action :authenticate
    
      protected
    
      def authenticate
        authenticate_token || render_unauthorized
      end
    
      def authenticate_token
        authenticate_with_http_token do |token, options|
          @current_user = User.find_by(api_key: token)
        end
      end
    
      def render_unauthorized(realm = "Application")
        self.headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
        render json: {error: "Bad Credentials"}, status: :unauthorized
      end
    end
    ```

8. If you restart the server now and try to use Swagger to test out any of the endpoints in any controller, you will be faced with the Bad Credentials message. To fix this we need to change the swagger docs so that it will pass along the token in the headers of every request. There are two ways to do this, one way is to add another header param to every single endpoint; another way is to add a setup method for swagger docs to pick up. In order to do this, all we need to do is write this singleton class within in the ApplicationController class so that it will affect all of the other controllers. All this does is it goes to all the subclasses of ApplicationController and then adds the header param to each of the actions. 

    ```ruby
    class << self
      def inherited(subclass)
        super
        subclass.class_eval do
          setup_basic_api_documentation
        end
      end
    
      private
      def setup_basic_api_documentation
        [:index, :show, :create, :update, :delete].each do |api_action|
          swagger_api api_action do
            param :header, 'Authorization', :string, :required, 'Authentication token in the format of: Token token=<token>'
          end
        end
      end
    end
    ```

9. Make sure you run ```rails swagger:docs```, start up the server and check out the swagger docs. For each endpoint, there should be a header param. In order to successfully hit any of the endpoints, you will need to fill out this param too. This is a little bit more complicated as before since rails has its own format/way to do things. In the input box, enter ```Token token=<api_token>``` and replace <api_token> with the token from the user you created before. Now check that the API works with the token authentication!


# <span class="mega-icon mega-icon-issue-opened"></span>Stop

Show a TA that you have the whole ChoreTracker API working with all its components! Also show the TA your git log so he/she can see that you've made regular commits. Make sure the TA signs your sheet.
* * *



# Part 7 - Versioning



# Part 8 - Rack Attack

1. When developing an API in the real world, there are more things that you need to take care of before you put your application in production. One major thing is adding a layer of middleware to protect against malicious attacks. Middleware is everything that exists between your application server (what actually hosts your web app) and the actual Rails application. So what happens when you have an user that just keeps on spamming your API and slowing down your service? Well there are ways to prevent that through your middleware by throttling those users (basically telling them to back off a little bit before hitting your server again). One such middleware is Rack::Attack!!

2. First you need to include Rack Attack in your gem file and run bundle install.

    ``` ruby
    gem 'rack-attack'
    ```

3. Then you need to setup an initializer in order for Rack Attack to work. All you need to do is go to ```config/initializers/``` and create a new file called rack_attack.rb and put the following in the file. All this means is that you are throttling (or limiting) hits from users by their ip addresses and you are setting the limit to 3 hits within 10 seconds. Usually that number should be a lot higher, but we kept it low just for testing purposes.

    ```ruby
    class Rack::Attack 
      Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new 
    
      throttle('req/ip', limit: 3, period: 10) do |req|
        req.ip
      end
    end
    ```

4. Before you go on you will also need to add the following to your ```config/application.rb``` file.

    ```ruby
    module ChoreTrackerAPI
      class Application < Rails::Application
        # Exisiting code
    
        config.middleware.use Rack::Attack
      end
    end
    ```

5. Now if you use Swagger Docs or Curl to hit your RESTful API 4 times quickly! You will find that on the 4th try you will be rejected with a Retry Later message. This may not look very consistent with the rest of the JSON response, so we need to change how the error message is displayed. To do so, go back to the initializer and change the code to the following. We will not go through exactly what the code means, but it generally means that it will respond instead with a JSON object with the 429 error code.

    ```ruby
    class Rack::Attack 
      Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new 
    
      throttle('req/ip', limit: 3, period: 10) do |req|
        req.ip
      end
    
      self.throttled_response = ->(env) {
        retry_after = (env['rack.attack.match_data'] || {})[:period]
        [
          429,
          {'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s},
          [{error: "Throttle limit reached. Retry later."}.to_json]
        ]
      }
    end
    ```

6. Now your application will be protected against any user/from an ip address from spamming your API and slowly down your server!
