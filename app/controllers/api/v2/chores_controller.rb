module Api::V2 
  class ChoresController < ApplicationController
    # This is to tell the gem that this controller is an API
    swagger_controller :chores, "Chores Management"

    # Each API endpoint index, show, create, etc. has to have one of these descriptions

    # This one is for the index action. The notes param is optional but helps describe what the index endpoint does
    swagger_api :index do
      summary "Fetches all Chores"
      notes "This lists all the chores"
      param :query, :done, :boolean, :optional, "Filter on whether or not the chore is done"
      param :query, :upcoming, :boolean, :optional, "Filter on whether or not the chore is upcoming"
      param :query, :by_task, :boolean, :optional, "Order chores by task"
      param :query, :chronological, :boolean, :optional, "Order chores by chronological"
    end

    # Show needs a param which is which chore id to show.
    # The param defines that it is in the path, and that it is the Chore's ID
    # The response params here define what type of error responses can be returned back to the user from your API. In this case the error responses are 404 not_found and not_acceptable.
    swagger_api :show do
      summary "Shows one Chore"
      param :path, :id, :integer, :required, "Chore ID"
      notes "This lists details of one chore"
      response :not_found
    end

    # Create doesn't take in the chore id, but rather the required fields for a chore (namely first_name and last_name)
    # Instead of a path param, this uses form params and defines them as required
    swagger_api :create do
      summary "Creates a new Chore"
      param :form, :child_id, :integer, :required, "Child ID"
      param :form, :task_id, :integer, :required, "Task ID"
      param :form, :due_on, :date, :required, "Due On"
      param :form, :completed, :boolean, :required, "Completed"
      response :not_acceptable
    end

    # Update requires the chore id but you can also change the first_name and/or last_name of the chore.
    # Again since it takes in an chore id, it can be not found.
    # Also this will have both path and form params
    swagger_api :update do
      summary "Updates an existing Chore"
      param :path, :id, :integer, :required, "Chore ID"
      param :form, :child_id, :integer, :optional, "Child ID"
      param :form, :task_id, :integer, :optional, "Task ID"
      param :form, :due_on, :date, :optional, "Due On"
      param :form, :completed, :boolean, :optional, "Completed"
      response :not_found
      response :not_acceptable
    end

    # Lastly destroy is just like the rest and just takes in the param path for chore id. 
    swagger_api :destroy do
      summary "Deletes an existing Chore"
      param :path, :id, :integer, :required, "Chore Id"
      response :not_found
    end


    # Controller Code

    before_action :set_chore, only: [:show, :update, :destroy]

    # GET /chores
    def index
      @chores = Chore.all
      if(params[:done].present?)
        @chores = params[:done] == "true" ? @chores.done : @chores.pending
      end
      if(params[:upcoming].present?)
        @chores = params[:upcoming] == "true" ? @chores.upcoming : @chores.past
      end

      if params[:by_task].present? && params[:by_task] == "true"
        @chores = @chores.by_task
      end
      if params[:chronological].present? && params[:chronological] == "true"
        @chores = @chores.chronological
      end

      render json: @chores
    end

    # GET /chores/1
    def show
      render json: @chore
    end

    # POST /chores
    def create
      @chore = Chore.new(chore_params)

      if @chore.save
        render json: @chore, status: :created, location: [:v1, @chore]
      else
        render json: @chore.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /chores/1
    def update
      if @chore.update(chore_params)
        render json: @chore
      else
        render json: @chore.errors, status: :unprocessable_entity
      end
    end

    # DELETE /chores/1
    def destroy
      @chore.destroy
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_chore
        @chore = Chore.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def chore_params
        params.permit(:child_id, :task_id, :due_on, :completed)
      end
  end
end
