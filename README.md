  # ChoreTracker API Lab

  ### Objective

  In this lab we will be creating an RESTful API version of the ChoreTracker application, which means there are no need for views (just controller and model code). There will be 4 things that will be covered in this lab:

  1. Creating the API itself
  2. Documenting the API with swagger docs
  3. Serialization Customizations
  4. Stateless authentication for the API

  ### Instructions

  #### Building the API

  1. We will not be using any starter code for this application since everything will be built from scratch to help you understand the full process. First of all create a new rails application using the api flag and call it ChoreTrackerAPI. THe api flag allows rails to know how the application is intended to be used and will make sure to set up the right things in order to make the application RESTful.

  ```
  $ rails new ChoreTrackerAPI --api
  ```

  2. Just as the ChoreTracker that you have build before there will be 3 main entities to the ChoreTracker application, please review the old lab if you want any clarifications on the ERD. Based on these specifications, please generate all the models with all the proper fields and then run ```rake db:migrate```. This step should be the same as if you were building a regular rails application. (ex. ```rails generate model Child first_name:string last_name:string active:boolean```)
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

  3. Now add in the model code below for each of the models. The code here is exactly the same as what you have done in the old ChoreTracker Application, which is why we won't require you to rewrite everything! (Note: don't forget to add the validates_timeliness gem to the Gemfile in order to get some of the validations to work.)

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

  4. Now we will be starting to build out the controllers for the models that we just built. As you remember, we will not be building any views since literally all user output from a RESTful API is just JSON (no need for HTML/CSS/JS). First let's go through the process of creating the controller for the Child model and then you will need create the controllers for the other 2 models. So unlike in a normal rails application, in a RESTful one, you will only need 5 (**index, show, create, update, and destroy**) actions instead of 7. We won't be needing the new or edit action since those were only used to display the form, and with only JSON responses, the form will no longer be needed. Create a file called children_controller.rb in the controllers folder, define the class and follow along! (Note: One thing to note here is the idea of the status code. This is especially important when developing a RESTful API to tell users of it what happened. All success type codes (ok, created, etc.) are in the 200 number ranges, and generally other error statuses are either in the 400 or 500 ranges.)
    a. Index Action (responds to GET) is used to display all of the children that exist and its information/fields. So in this case all you need is to render all of the children objects as json.
    b. Show Action (responds to GET) just like before, given a child id from the url path, it will display the information for just that child. This uses the ```set_child method``` to the set the instance variable @child before rendering it.
    c. Create Action (responds to a POST) actually creates a new child given the proper params. Using the ```child_params``` method it gets all the whitelisted params and tries to create a new child. If it properly saves, it will just render the JSON of the child that was just created and attached with a created success status code. If it fails to save, then it will respond with a JSON of all the validation errors and a unprocessably_entity error status code. 
    d. Update Action (responds to PATCH) updates the information of a child given its ID. The @child variable will be set from the ```set_child``` method and then be populated with the child parameters. Again it will do something similar to create where it checks if the child is valid and return the proper JSON response. 
    e. Delete Action (responds to DELTE) deletes the child given its ID which is set from the ```set_child``` method. 
    f. Lastly don't forget to add the proper routes to the routes.rb file. ```resources :children``` should take care of all the routes for your children controller.

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

  5. Now we want to test that our API actually works! Here are just some simple things to test out (Note: Whenever we mention the word endpoint, it is just another way to say action of your controller since each action is an endpoint of your API that you can hit with a GET or POST request):
    a. Go to http://localhost:3000/children and an empty array should appear. This triggers the index action with the GET request and display no children, since none have been created yet.
    b. Now we should test how creating a new child. Since we can't easily send POST requests in the browser (not as easy as GET) we will be needing CURL. CURL is a command that you can run in your terminal to hit certain endpoints with GET, POST, etc. requests.
      - Check that ```curl -X GET -H "Accept: application/json" "http://localhost:3000/children"``` will return an empty list just like it did in the browser.
      - Now run ```curl -X POST --data "first_name=Test&last_name=Child&active=true" -H "Accept: application/json" "http://localhost:3000/children"``` which should return a success status.
      - Check that it has been created by either CURLing the index action or going to the url on chrome.
      - Feel free to test out all the other endpoints if you have time!

  6. Now that you already created the Children Controller, you will need to follow the similar structure and create the controller for the Tasks and Chores Controllers!

  - - -
# <span class="mega-icon mega-icon-issue-opened"></span> Stop
Show a TA that you have properly created the barebone API for the ChoreTracker!


#### Documenting the API using Swagger Docs/UI

1. Now that you have created the API you will need to document it. Documentation is **crucial** for RESTful API's since there is no views tied to the application, which means there is no way for users to know what endpoints exist and what capabilities the API has. Good thing that there is a easy to way autogenerate some nice Documentation using Swagger for your API.
  a. There are 2 main portions of swagger documentation. There is the Swagger Doc and Swagger UI. Swagger Doc is a representation that is autogenerated to describe your api and each endpoint (which is in JSON format) and Swagger UI is the HTML/CSS/JS that is autogenerated from the Swagger Doc.

2. First we need to set up swagger docs for the RESTful API application. Include the swagger docs gem in your Gemfile ```gem 'swagger-docs'``` and then run ```bundle install```
  a. This gem will automatically generate the right JSON files to help document your API if provided the right things. The documentation for the gem is here: https://github.com/richhollis/swagger-docs 

3. Next you will need to create an initializer for the gem and call it swagger_docs.rb. This will tell the gem some basic information about your application and how to generate the JSON for your API. This should go in your ```config/initializers/swagger_docs.rb``` file that you just created. You won't need to fully understand what this whole thing does, but its good to know that all of the autogenerated Swagger Doc files are put in the ```public/apidocs``` folder.

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

4. Now that you have set up your swagger docs, you are ready to actually document your API. Again we are only going through documenting your Children Controller and you will need to do the rest without guidance. First go to your children_controller.rb file, since all the documentation that you need to add should be in that file. This is because you are only documenting each endpoint and each endpoint is only defined in the controller itself. Step by step add in documentation within the ChildrenController class above the controller code by following the instructions below:
  a. Tell the swagger-docs gem that the children controller is an api and give it a name
  ```
  swagger_controller :children, "Children Management"
  ```

  b. Document the index action by saying what it does
  ```
  swagger_api :index do
    summary "Fetches all Children"
    notes "This lists all the children"
  end
  ```

  c. Document the show action. This is a bit more complicated as it requires some parameters, namely the child id in the url path. Params are defined by type (path, form, header), the name of the parameter, the type of the parameter, whether or not it is required, and the description. You can probably also see that it has 2 different responses, and this is describing what type of error response statuses can be returned from this endpoint. In this case, it will return not_found if the child id is invalid.
  ```
  swagger_api :show do
    summary "Shows one Child"
    param :path, :id, :integer, :required, "Child ID"
    notes "This lists details of one child"
    response :not_found
  end
  ```

  d. Next we need to document the create action. Just like with the show action, we need params for the create but this time we will also need form params to pass through describing the fields of the child including the first_name, last_name, and active. This time we won't need the not_found response, but rather the not_acceptable response if there is anything wrong with the actual creation of the child (most likely some validation error).
  ```
  swagger_api :create do
    summary "Creates a new Child"
    param :form, :first_name, :string, :required, "First name"
    param :form, :last_name, :string, :required, "Last name"
    param :form, :active, :boolean, :required, "Active"
    response :not_acceptable
  end
  ```

  e. The update action if like the combination of the show and create where we need the path param of the child id and the form params to describe the child. However, for updates, none of the fields should be required as users should be able to update only the fields that they want.
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

  f. Lastly is the delete action and this is rather simple since it only needs one param.
  ```
  swagger_api :destroy do
    summary "Deletes an existing Child"
    param :path, :id, :integer, :required, "Child Id"
    response :not_found
  end
  ```

  5. 









