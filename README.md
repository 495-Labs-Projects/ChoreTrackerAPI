# Objectives

In this lab we will continue to work on the Chore Tracker API and adding additional features to it. There will be 4 things that will be covered in this lab:

- Filtering and Odering the index action
- Stateless authentication for the API
- Versioning the API
- Throttling API usage


# Part 5 - Filtering and Ordering

After the first API lab you should already have a working API. One thing that we will be improving upon in this lab is filtering and ordering. This is mainly for the the index action of each controller and allows users of your API to filter out and order the list of objects. For example, if you want to get all the active tasks right now, you will have to hit the ```/tasks``` endpoint to get all the tasks back and then filter out the inactive ones manually using Javascript. However, a better option would be to pass in an active parameter that states what you want. So for the example, ```/tasks?active=true``` will get you all the active tasks, ```/tasks?active=false``` will get you all the inactive tasks, and ```/tasks``` will get you all the tasks. With the format, you can concat different filters and ordering together.

1. Let's first add this feature to the ```children_controller.rb```. Open up the ```child.rb``` model file first and notice the scopes that are present (:active and :alphabetical). :active is a filtering scope and :alphabetical is a ordering scope. In this case, we will probably need another scope called ```:inactive``` to be the opposite of the :active filtering scope. Add the following :inactive scope to the child model file:

    ```ruby
    scope :inactive, -> {where(active: false)}
    ```

2. Now go the ChildrenController and let's add this new active filter to the index action. In this case, the ```:active``` param will be the one that triggers the filter, and do nothing if the param isn't present. Also the only reason that we are checking if it's equal to the string "true" is that params are all treated as strings. Copy the following code into the index action (ask a TA for help if you don't understand the logic here):

    ```ruby
    def index
      @children = Child.all
      if(params[:active].present?)
        @children = params[:active] == "true" ? @children.active : @children.inactive
      end

      render json: @children
    end
    ```

3. Since there was also a ```:alphabetical``` ordering scope, we will need to add that to the index action too. In this case, it will behave slightly different than the filtering scope. This is because it will only alphabetically order the children if the ```:alphabetical``` param is present and true. Add the following right after the active filter param in the index action:

    ```ruby
    if params[:alphabetical].present? && params[:alphabetical] == "true"
      @children = @children.alphabetical
    end
    ```

4. Now before we test this out, we will need to add the proper params to the swagger docs. Add the following ```:query``` params to the ChildrenController's swagger docs' index action and test it out (**Note**: don't forget to run ```rails swagger:docs``` afterwards):

    ```ruby
    param :query, :active, :boolean, :optional, "Filter on whether or not the child is active"
    param :query, :alphabetical, :boolean, :optional, "Order children by alphabetical"
    ```

5. After you tested everything out for children with swagger docs, we will move on to doing the same thing for tasks and chores. Since Tasks is basically the same as Children, you will be completing the ```:active``` and ```:alphabetical``` filtering/ordering scopes on your own. (**Note**: Make sure you add the necessary scopes to the task model.)

6. Chores is a bit more complicated but not that much. All the necessary scopes are there for you. You wil be creating the filtering params on your own for ```:done``` and ```:upcoming``` (where ```:pending``` and ```:past``` are the opposite scopes respectively). Also you will be creating the ordering params ```:alphabetical``` and ```:by_task```. 

7. Make sure you add all the appropriate swagger docs to the index actions of each controller and test out the filtering/ordering params.


# <span class="mega-icon mega-icon-issue-opened"></span>Stop

Show a TA that you have all the filtering and ordering params working for all the controllers. 
* * *



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

4. Now we should create the User controller and the Swagger Docs for the controller. This should be quick since you have done this already for all the other controllers. (Note: make sure that the user params method permits these parameters because we don't want them creating the api_key: params.permit(:email, :password, :password_confirmation, :role, :api_key, :active)) After you are done, verify that it is the same as below and make sure the create documentation has the right form parameters. **Also add the user resources to the routes.rb and run ```rails swagger:docs```**

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

10. Now that you have the token authentication implemented for each of the endpoints, there's no way for someone to access the api if they forgot their token. However, a user will most likely still remember their email/password, which is why we will need to create one more endpoint where users will be able to retrieve their token with their correct email/password. Let's call this endpoint ```/token```. First you will need to add a helper method to your user model that authenticates the user by email and password:

    ```
    # login by email address
    def self.authenticate(email, password)
      find_by_email(email).try(:authenticate, password)
    end
    ```

11. Also add the following to the ```application_controller.rb``` file/class along with all the other authentication code. We are using something called Basic Http Authentication which is provided by rails, that authenticates with email and password. However, since it is rails, we will need to do everything the rails way. The way they intake the email/password is through the ```Authorization``` header and it needs to be in the format of ```Basic <Base64.encode64('email:password')>```. Let's say that the email and password for a user is "test@example.com" and "password" respectively (and the encoded email:password is "dGVzdEBleGFtcGxlLmNvbTpwYXNzd29yZA==\n") then the full header should be "Authorization: Basic dGVzdEBleGFtcGxlLmNvbTpwYXNzd29yZA==\n"

    ```ruby
    include ActionController::HttpAuthentication::Basic::ControllerMethods

    before_action :authenticate, except: [:token]

    # A method to handle initial authentication
    def token
      authenticate_username_password || render_unauthorized
    end

    protected

    def authenticate_username_password
      authenticate_or_request_with_http_basic do |email, password|
        user = User.authenticate(email, password)
        if user
          render json: user
        end
      end
    end
    ```

11. After adding this don't forget to all the token action to the ```routes.rb``` file.

12. Also now that you have an endpoint in the application controller, you will need to add swagger docs to it. 

    ```ruby
    swagger_controller :application, "Application Management"

    swagger_api :token do |api|
      summary "Authenticate with email and password to get token"
      param :header, "Authorization", :string, :required, "Email and password in the format of: Basic {Base64.encode64('email:password')}"
    end
    ```

13. After running ```rails swagger:docs``` you can test out the token endpoint to see if you are able to get the user's token with the email and password. (**Note**: as mentioned before the format of the Authorization header is supposed to be: ```Basic <Base64.encode64('email:password')>```)


# <span class="mega-icon mega-icon-issue-opened"></span>Stop

Show a TA that you have the whole ChoreTracker API is authenticated properly with the token endpoint as well.
* * *



# Part 7 - Versioning

Versioning your API is crucial! Before releasing your public API to the public, you should consider implementing some form of versioning. Versioning breaks your API up into multiple version namespaces, such as ```v1``` and ```v2```, so that you can maintain backwards compatibility for existing clients whenever you introduce breaking changes into your API, simply by incrementing your API version.

In this lab we will be setting up versioning in the following format (i.e. ```GET http://localhost:3000/v1/children/```):

```
http://<domain>/<version>/<route>
```

1. Since you only have one version of your api, you will need to put all your controllers under the namespace ```Api::V1```. We only need to make the changes to the controller and not the models because the only main changes that should happen to an API is in the controllers and serializers. Rearrange all of your controllers into this folder structure:

    ```
    app/controllers/
    .
    |-- api
    |   |-- v1
    |       |-- application_controller.rb
    |       |-- children_controller.rb
    |       |-- chores_controller.rb
    |       |-- tasks_controller.rb
    |       |-- users_controller.rb
    ```

3. Because you have changed the folder structure for all of your controllers, you will also need to update the module naming scheme for each controller (add ```module Api::V1```). Follow the pattern below for the ```application_controller.rb``` and make the necessary changes for all the controllers:

    ```ruby
    module Api::V1
      class ApplicationController < ActionController::API
        # Some Controller Code
        # ...
      end
    end
    ```

4. Now that you have completed all the necessary changes to your controllers, you will need to make similar changes to the serializers. You will need to modify the folder structure in the same way too (using ```api/v1/<serializers>```) and adding the ```module Api::V1``` to all the serializers. 

5. After you have properly fixed all the namespaces for the controllers and serializers, we need to fix the same namespace issue with the routes. As mentioned before, we want our routes to be formatted something like this ```http://localhost:3000/v1/children/```. All you need to do is add ```scope module: 'api' do``` and ```namespace :v1 do```. This allows the route to be ```/v1/children/``` instead of ```/api/v1/children```, but at the same time be able to find the right namespace of ```Api::V1```. (Note: If later on, you want the routes to be ```/api/v1/children``` then all you need to do is to change ```scope module: 'api' do``` to ```namespace :api do```.)

    ```ruby
    Rails.application.routes.draw do
      scope module: 'api' do
        namespace :v1 do
          resources :children
          resources :tasks
          resources :chores
          resources :users

          get :token, controller: 'application'
        end
      end
    end
    ```

6. Make sure you restart your server and run ```rails swagger:docs``` again so the swagger docs can have the updated routes. Now you should test that the API routes are working.



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
        # Other code
        # ...
    
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
