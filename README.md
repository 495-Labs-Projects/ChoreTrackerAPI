# Objectives

In this lab we will be creating an RESTful API version of the ChoreTracker application, which means there are no need for views (just controller and model code). There will be 4 things that will be covered in this lab:

- Creating the API itself
- Documenting the API with swagger docs
- Serialization Customizations
- Stateless authentication for the API


# Part 1 - Building the API

1. We will not be using any starter code for this application since everything will be built from scratch to help you understand the full process. First of all create a new rails application using the api flag and call it ChoreTrackerAPI. The api flag allows rails to know how the application is intended to be used and will make sure to set up the right things in order to make the application RESTful.

  ```
  $ rails new ChoreTrackerAPI --api
  ```

2. 2. Just like the ChoreTracker app that you have built before, there will be 3 main entities to the ChoreTracker application, please review the old lab if you want any clarifications on the ERD. The following are the data dictionaries for the 3 models. Based on these specifications, please generate all the models with all the proper fields and then run ```rails db:migrate```. This step should be the same as if you were building a regular rails application. (ex. ```rails generate model Child first_name:string last_name:string active:boolean```)
  - Child
    - first_name (string)
    - last_name (string)
    - active (boolean)
  - Task
    - name (string)
    - points (integer)
    - active (boolean)
  - Chore
    - child_id (integer)
    - task_id (integer)
    - due_on (date)
    - completed (boolean)

3. Now add in the model code below for each of the models. The code here is exactly the same as what you have done in the old ChoreTracker Application, which is why we won't require you to rewrite everything! (**Note: don't forget to add the validates_timeliness gem to the Gemfile in order to get some of the validations to work.**)

  ```ruby
  class Child < ApplicationRecord
    has_many :chores
    has_many :tasks, through: :chores

    validates_presence_of :first_name, :last_name

    scope :alphabetical, -> { order(:last_name, :first_name) }
    scope :active, -> {where(active: true)}

    def name
      return first_name + " " + last_name
    end

    def points_earned
      self.chores.done.inject(0){|sum,chore| sum += chore.task.points}
    end 
  end
  ```

  ```ruby
  class Task < ApplicationRecord
    has_many :chores
    has_many :children, through: :chores

    validates_presence_of :name
    validates_numericality_of :points, only_integer: true, greater_than_or_equal_to: 0

    scope :alphabetical, -> { order(:name) }
    scope :active, -> {where(active: true)}
  end
  ```

  ```ruby
  class Chore < ApplicationRecord
    belongs_to :child
    belongs_to :task

    # Validations
    validates_date :due_on
    
    # Scopes
    scope :by_task, -> { joins(:task).order('tasks.name') }
    scope :chronological, -> { order('due_on') }
    scope :done, -> { where('completed = ?', true) }
    scope :pending, -> { where('completed = ?', false) }
    scope :upcoming, -> { where('due_on >= ?', Date.today) }
    scope :past, -> { where('due_on < ?', Date.today) }
    
    # Other methods
    def status
      self.completed ? "Completed" : "Pending"
    end
  end
  ```

4. Now we will be starting to build out the controllers for the models that we just made. First, let's create a file called ```children_controller.rb``` in the controllers folder, define the class and follow along!

5. As you remember, we will not be building any views since literally all user output from a RESTful API is just JSON (no need for HTML/CSS/JS). First let's go through the process of creating the controller for the Child model and then you will need create the controllers for the other 2 models. So unlike in a normal rails application, in a RESTful one, you will only need 5 (**index, show, create, update, and destroy**) actions instead of 7. We won't be needing the new or edit action since those were only used to display the form, and with only JSON responses, the form will no longer be needed.  (Note: One thing to note here is the idea of the status code. This is especially important when developing a RESTful API to tell users of it what happened. All success type codes (ok, created, etc.) are in the 200 number ranges, and generally other error statuses are either in the 400 or 500 ranges.)
    1. Index Action (responds to GET) is used to display all of the children that exist and its information/fields. So in this case all you need is to render all of the children objects as json.
  
    2. Show Action (responds to GET) just like before, given a child id from the url path, it will display the information for just that child. This uses the ```set_child method``` to the set the instance variable @child before rendering it.
  
    3. Create Action (responds to a POST) actually creates a new child given the proper params. Using the ```child_params``` method it gets all the whitelisted params and tries to create a new child. If it properly saves, it will just render the JSON of the child that was just created and attached with a created success status code. If it fails to save, then it will respond with a JSON of all the validation errors and a unprocessably_entity error status code. You might have also noticed this new thing called ```location```, this is a param in the header so that the client will be able to know where this newly created child is (in this case it's the child show page).
  
    4. Update Action (responds to PATCH) updates the information of a child given its ID. The @child variable will be set from the ```set_child``` method and then be populated with the child parameters. Again it will do something similar to create where it checks if the child is valid and return the proper JSON response. 
  
    5. Delete Action (responds to DELTE) deletes the child given its ID which is set from the ```set_child``` method. 
  
    6. Lastly don't forget to add the proper routes to the routes.rb file. ```resources :children``` should take care of all the routes for your children controller.

  ```ruby
  class ChildrenController < ApplicationController
    # Controller Code

    before_action :set_child, only: [:show, :update, :destroy]

    # GET /children
    def index
      @children = Child.all

      render json: @children
    end

    # GET /children/1
    def show
      render json: @child
    end

    # POST /children
    def create
      @child = Child.new(child_params)

      if @child.save
        render json: @child, status: :created, location: @child
      else
        render json: @child.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /children/1
    def update
      if @child.update(child_params)
        render json: @child
      else
        render json: @child.errors, status: :unprocessable_entity
      end
    end

    # DELETE /children/1
    def destroy
      @child.destroy
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_child
        @child = Child.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def child_params
        params.permit(:first_name, :last_name, :active)
      end
  end
  ```

6. Now we want to test that our API actually works! Here are just some simple things to test out (Note: Whenever we mention the word endpoint, it is just another way to say action of your controller since each action is an endpoint of your API that you can hit with a GET or POST request):
    1. Go to http://localhost:3000/children and an empty array should appear. This triggers the index action with the GET request and display no children, since none have been created yet.
    
    2. Now we should test how creating a new child. Since we can't easily send POST requests in the browser (not as easy as GET) we will be needing CURL. CURL is a command that you can run in your terminal to hit certain endpoints with GET, POST, etc. requests.
      - Check that ```curl -X GET -H "Accept: application/json" "http://localhost:3000/children"``` will return an empty list just like it did in the browser.
      - Now run ```curl -X POST --data "first_name=Test&last_name=Child&active=true" -H "Accept: application/json" "http://localhost:3000/children"``` which should return a success status.
      - Check that it has been created by either CURLing the index action or going to the url on chrome.
      - Feel free to test out all the other endpoints if you have time!

7. Now that you already created the Children Controller, **you will need to follow the similar structure and create the controller for the Tasks and Chores Controllers**!


# <span class="mega-icon mega-icon-issue-opened"></span>Stop

Show a TA that you have completed the first part. Make sure the TA initials your sheet.

* * *


# Part 2 - Documenting the API using Swagger Docs/UI

1. Now that you have created the API you will need to document it. Documentation is **crucial** for RESTful API's since there is no views tied to the application, which means there is no way for users to know what endpoints exist and what capabilities the API has. Good thing that there is a easy to way autogenerate some nice Documentation using Swagger for your API.
  - There are 2 main portions of swagger documentation. There is the Swagger Doc and Swagger UI. Swagger Doc is a representation that is autogenerated to describe your api and each endpoint (which is in JSON format) and Swagger UI is the HTML/CSS/JS that is autogenerated from the Swagger Doc.

2. First we need to set up swagger docs for the RESTful API application. **Include the swagger docs gem in your Gemfile ```gem 'swagger-docs'``` and then run ```bundle install```**
  - This gem will automatically generate the right JSON files to help document your API if provided the right things. The documentation for the gem is here: https://github.com/richhollis/swagger-docs 

3. Next you will need to create an initializer for the gem and call it swagger_docs.rb. This will tell the gem some basic information about your application and how to generate the JSON for your API. This should go in your ```config/initializers/swagger_docs.rb``` file that you just created. You won't need to fully understand what this whole thing does, but its good to know that all of the autogenerated Swagger Doc files are put in the ```public/apidocs``` folder. (**Note:** If you are using cloud9 epecially or aren't running it on localhost:3000, make sure to change the ```:base_path``` property to the appropriate host name and port.)

  ```ruby
  # config/initializers/swagger_docs.rb

  class Swagger::Docs::Config
    def self.transform_path(path, api_version)
      # Make a distinction between the APIs and API documentation paths.
      "apidocs/#{path}"
    end
  end

  Swagger::Docs::Config.base_api_controller = ActionController::API 

  Swagger::Docs::Config.register_apis({
    "1.0" => {
      # the extension used for the API
      :api_extension_type => :json,
      # the output location where your .json files are written to
      :api_file_path => "public/apidocs",
      # the URL base path to your API (make sure to change this if you are not using localhost:3000)
      :base_path => "http://localhost:3000",
      # if you want to delete all .json files at each generation
      :clean_directory => false,
      # add custom attributes to api-docs
      :attributes => {
        :info => {
          "title" => "Chore Tracker API",
          "description" => "Uses swagger ui and docs to document the ChoreTracker API"
        }
      }
    }
  })
  ```

4. Now that you have set up your swagger docs, you are ready to actually document your API. Again we are only going through documenting your Children Controller and you will need to do the rest without guidance. First go to your ```children_controller.rb file```, since all the documentation that you need to add should be in that file. This is because you are only documenting each endpoint and each endpoint is only defined in the controller itself. Step by step add in documentation **within the ChildrenController class** and above the controller code (above the before_action) by following the instructions below:
  1. Tell the swagger-docs gem that the children controller is an api and give it a name
    ```
    swagger_controller :children, "Children Management"
    ```

  2. Document the index action by saying what it does
    ```
    swagger_api :index do
      summary "Fetches all Children"
      notes "This lists all the children"
    end
    ```

  3. Document the show action. This is a bit more complicated as it requires some parameters, namely the child id in the url path. Params are defined by type (path, form, header), the name of the parameter, the type of the parameter, whether or not it is required, and the description. You can probably also see that it has 2 different responses, and this is describing what type of error response statuses can be returned from this endpoint. In this case, it will return not_found if the child id is invalid.
    ```
    swagger_api :show do
      summary "Shows one Child"
      param :path, :id, :integer, :required, "Child ID"
      notes "This lists details of one child"
      response :not_found
    end
    ```

  4. Next we need to document the create action. Just like with the show action, we need params for the create but this time we will also need form params to pass through describing the fields of the child including the first_name, last_name, and active. This time we won't need the not_found response, but rather the not_acceptable response if there is anything wrong with the actual creation of the child (most likely some validation error).
    ```
    swagger_api :create do
      summary "Creates a new Child"
      param :form, :first_name, :string, :required, "First name"
      param :form, :last_name, :string, :required, "Last name"
      param :form, :active, :boolean, :required, "Active"
      response :not_acceptable
    end
    ```

  5. The update action is like the combination of the show and create where we need the path param of the child id and the form params to describe the child. However, for updates, none of the fields should be required as users should be able to update only the fields that they want.
    ```
    swagger_api :update do
      summary "Updates an existing Child"
      param :path, :id, :integer, :required, "Child Id"
      param :form, :first_name, :string, :optional, "First name"
      param :form, :last_name, :string, :optional, "Last name"
      param :form, :active, :boolean, :optional, "Active"
      response :not_found
      response :not_acceptable
    end
  ```

  6. Lastly is the delete action and this is rather simple since it only needs one param.
    ```
    swagger_api :destroy do
      summary "Deletes an existing Child"
      param :path, :id, :integer, :required, "Child Id"
      response :not_found
    end
    ```

5. Now that you have wrote up the documentation for the rails api, you can generate the Swagger Docs by running the following command. You should verify that it was properly created by checking the ```public/apidocs/``` folder and seeing if it contains 2 files (api-docs.json and children.json). api-docs.json contains the general info about your api and each controller should have one json file for it. (**Note:** You might encounter something like this when you run the following: ```2 process / 3 skipped``` Just because it says skipped doesn't mean something went wrong! You can just keep on going.)

  ```
  $ rails swagger:docs
  ```

6. After you generate the Swagger Docs, your next step is to get swagger ui to display the JSON in a user friendly manner using Swagger UI! Change your directory to the public folder:

  ```
  $ cd public/
  ```

7. Then include the Swagger UI in the public folder as a git submodule under the folder name api/. You should now have a folder under public/api/ where all of swagger ui files (html, css, javascript) will be.

  ```
  $ git submodule add https://github.com/495-Labs-Projects/RailsSwaggerUI api
  ```

  

8. Start up your server using ```rails s``` and then go to ```http://localhost:3000/api``` and you should see something like this:

  ![](https://github.com/495-Labs-Projects/ChoreTrackerAPI/raw/master/public/swagger_screenshot.png "Swagger UI Screenshot")

9. Play around with the swagger docs and try to view, create, edit, and delete different children using the Swagger Docs/UI. This documents and makes interactions with your API endpoints much more easier and you won't need to use curl to hit an endpoint.

10. Now that you created this for the children_controller, create documentation for both the tasks_controller and chores_controller, by adding in similar documentation code in the file itself. Remember to run ```rails swagger:docs``` every time you make a change to your documentation. (Note: Create a couple of Children, Tasks, and Chores to help test out things in the next part.)


  - - -
# <span class="mega-icon mega-icon-issue-opened"></span> Stop
Show a TA that you have properly created the documentation for the ChoreTrackerAPI!


# Part 3 - Custom Serialization

1. Once you have created the barebone API for ChoreTracker and documenting it, there are a lot more things you can do to improve it and make it more usable. One main thing is serialization, which is how Rails converts a Child/Task/Chore model object to JSON. With the active_model_serializers, you can truly customize how you want these objects to show up in your API. One good example of this is to display all the chores that are tied to a child when viewing the show action of a child. First of all add the gem to your gemfile: ```gem 'active_model_serializers'``` and run ```bundle install```.

2. Now you can actually generate some boiler plate code for your serializer, by running ```rails generate serializer <model_name>``` so for example, ```rails generate serializer child``` will create a new file called ```child_serializer.rb``` in the serializers folder in app. **Generate serializer files for each controller**.

3. By default for the child serializer you should just see the following. This means that when serializing a child object to JSON it will only display the id. To check that this is the case, start up your rails server and go to /children which is the index action. Now instead of the whole object with first_name and last_name, you should only see the id for each child, which is how the serializer is defined.
  ```
  class ChildSerializer < ActiveModel::Serializer
    attributes :id
  end
  ```

4. Let's start off by adding what we want to the ChildSerializer. In this case we want to display the id, name of the child, whether or not it is active, and the list of chores that it has. To do this, after the :id, also add :name and :active. The reason that name works even though the Child Model doesn't have a name attribute (only first_name and last_name) is because we had already defined a method call name in the Child Model that combines the first and last names. Next we need to get all the chores that is related to this child. To do so, we need to add a relationship, just like with the model by writing ```has_many :chores```. Your ChildSerializer should look something like the following. Verify that it worked by checking with Swagger Docs.
  ```
  class ChildSerializer < ActiveModel::Serializer
    attributes :id, :name, :active
    has_many :chores
  end
  ``` 

5. Let's go onto fixing the TaskSerializer. For this follow the same idea, but we only need to display the id, name, points that its worth, and whether or not it is active.

6. After that you should go on to adding serialization to the ChoreSerializer, which should include the id, child_id, task_id, due_on, and whether or not it is completed.

7. At this point you have just very standard serialization for each of these models. Let's make ChildSerializer more interesting! It would probably be useful to include the total number of points that the child has earned (good thing we wrote this function already in the model). Include that as an attribute of the ChildSerializer. Next, it probably makes more sense to break up the chores list into completed and unfinished chores for each child. You will need to write a custom method to do this and won't need the relationship to chores. In this case, the variable object will always represent the current object that you are trying to serialize, so we are getting all the chores tied to the specific child and running the done and pending scopes on it. After getting each of the relations, we still need to manually serialize each one using the ChoreSerializer class.
  ```ruby
  class ChildSerializer < ActiveModel::Serializer
    attributes :id, :name, :points_earned, :active, :completed_chores, :pending_chores

    def completed_chores
      object.chores.done.map do |chore|
        ChoreSerializer.new(chore)
      end
    end

    def pending_chores
      object.chores.pending.map do |chore|
        ChoreSerializer.new(chore)
      end
    end
    
  end
  ```

#### Optional
8. To make another improvement to the serialization is to actually allow users to preview what task the chore entails instead of just an id. This is a little bit more complex since we can't just have one serializer for tasks. We want one serializer that shows all information about a task when we hit the index action of the tasks controller, and we want another serializer that preview the task with just the id and the name. To do this we need another serializer! First make another file in the serializers folder and call it task_preview_serializer.rb and make a new class called TaskPreviewSerializer.

9. Now go to your chore_serializer and instead of dispaying task_id, have it display :task and write a custom serialization method called task. In this method all you need to return is the preview version of the serialized task. Call over a TA if you are having trouble with this concept! Now test if it worked by going to the /children endpoint! It should display the task id and name instead of just the task id.

  - - -
# <span class="mega-icon mega-icon-issue-opened"></span> Stop
Show a TA that you have properly serialized JSON objects in the ChoreTrackerAPI!

# Part 4 - Token Authentication

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


* * *

# <span class="mega-icon mega-icon-issue-opened"></span>Stop

Show a TA that you have the whole ChoreTracker API working with all its components! Also show the TA your git log so he/she can see that you've made regular commits. Make sure the TA signs your sheet.

# Bonus Section

1. When developing an API in the real world, there are more things that you need to take care of before you put your application in production. One major thing is adding a layer of middleware to protect against malicious attacks. Middleware is everything that exists between your application server (what actually hosts your web app) and the actual Rails application. So what happens when you have an user that just keeps on spamming your API and slowing down your service? Well there are ways to prevent that through your middleware by throttling those users (basically telling them to back off a little bit before hitting your server again). One such middleware is Rack::Attack!!

2. First you need to include Rack Attack in your gem file and run bundle install.

  ``` ruby
  gem 'rack-attack'
  ```

3. Then you need to setup an initializer in order for Rack Attack to work. All you need to do is go to ```config/initializers/``` and create a new file called rack_attack.rb and put the following in the file. All this means is that you are throttling (or limiting) hits from users by their ip addresses and you are setting the limit to 3 hits within 10 seconds. Usually that number should be a lot higher, but we kept it low just for testing purposes.

  ```
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

