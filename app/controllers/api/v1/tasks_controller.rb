module Api::V1
  class TasksController < ApplicationController
    # This is to tell the gem that this controller is an API
    swagger_controller :tasks, "Tasks Management"

    # Each API endpoint index, show, create, etc. has to have one of these descriptions

    # This one is for the index action. The notes param is optional but helps describe what the index endpoint does
    swagger_api :index do
      summary "Fetches all Tasks"
      notes "This lists all the tasks"
      param :query, :active, :boolean, :optional, "Filter on whether or not the task is active"
      param :query, :alphabetical, :boolean, :optional, "Order tasks by alphabetical"
    end

    # Show needs a param which is which task id to show.
    # The param defines that it is in the path, and that it is the Task's ID
    # The response params here define what type of error responses can be returned back to the user from your API. In this case the error responses are 404 not_found and not_acceptable.
    swagger_api :show do
      summary "Shows one Task"
      param :path, :id, :integer, :required, "Task ID"
      notes "This lists details of one task"
      response :not_found
    end

    # Create doesn't take in the task id, but rather the required fields for a task (namely first_name and last_name)
    # Instead of a path param, this uses form params and defines them as required
    swagger_api :create do
      summary "Creates a new Task"
      param :form, :name, :string, :required, "Name"
      param :form, :points, :integer, :required, "Points"
      param :form, :active, :boolean, :required, "Active"
      response :not_acceptable
    end

    # Update requires the task id but you can also change the first_name and/or last_name of the task.
    # Again since it takes in an task id, it can be not found.
    # Also this will have both path and form params
    swagger_api :update do
      summary "Updates an existing Task"
      param :path, :id, :integer, :required, "Task Id"
      param :form, :name, :string, :optional, "Name"
      param :form, :points, :integer, :optional, "Points"
      param :form, :active, :boolean, :optional, "Active"
      response :not_found
      response :not_acceptable
    end

    # Lastly destroy is just like the rest and just takes in the param path for task id. 
    swagger_api :destroy do
      summary "Deletes an existing Task"
      param :path, :id, :integer, :required, "Task Id"
      response :not_found
    end


    # Controller code

    before_action :set_task, only: [:show, :update, :destroy]

    # GET /tasks
    def index
      @tasks = Task.all
      if(params[:active].present?)
        @tasks = params[:active] == "true" ? @tasks.active : @tasks.inactive
      end

      if params[:alphabetical].present? && params[:alphabetical] == "true"
        @tasks = @tasks.alphabetical
      end

      render json: @tasks
    end

    # GET /tasks/1
    def show
      render json: @task
    end

    # POST /tasks
    def create
      @task = Task.new(task_params)

      if @task.save
        render json: @task, status: :created, location: @task
      else
        render json: @task.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /tasks/1
    def update
      if @task.update(task_params)
        render json: @task
      else
        render json: @task.errors, status: :unprocessable_entity
      end
    end

    # DELETE /tasks/1
    def destroy
      @task.destroy
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_task
        @task = Task.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def task_params
        params.permit(:name, :points, :active)
      end
  end
end