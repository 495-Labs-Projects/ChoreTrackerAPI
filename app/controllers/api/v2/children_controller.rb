module Api::V2 
  class ChildrenController < ApplicationController
      # This is to tell the gem that this controller is an API
    swagger_controller :children, "Children Management"

    # Each API endpoint index, show, create, etc. has to have one of these descriptions

    # This one is for the index action. The notes param is optional but helps describe what the index endpoint does
    swagger_api :index do
      summary "Fetches all Children"
      notes "This lists all the children"
      param :query, :active, :boolean, :optional, "Filter on whether or not the child is active"
      param :query, :alphabetical, :boolean, :optional, "Order children by alphabetical"
    end

    # Show needs a param which is which child id to show.
    # The param defines that it is in the path, and that it is the Child's ID
    # The response params here define what type of error responses can be returned back to the user from your API. In this case the error responses are 404 not_found and not_acceptable.
    swagger_api :show do
      summary "Shows one Child"
      param :path, :id, :integer, :required, "Child ID"
      notes "This lists details of one child"
      response :not_found
    end

    # Create doesn't take in the child id, but rather the required fields for a child (namely first_name and last_name)
    # Instead of a path param, this uses form params and defines them as required
    swagger_api :create do
      summary "Creates a new Child"
      param :form, :first_name, :string, :required, "First name"
      param :form, :last_name, :string, :required, "Last name"
      param :form, :active, :boolean, :required, "Active"
      response :not_acceptable
    end

    # Update requires the child id but you can also change the first_name and/or last_name of the child.
    # Again since it takes in an child id, it can be not found.
    # Also this will have both path and form params
    swagger_api :update do
      summary "Updates an existing Child"
      param :path, :id, :integer, :required, "Child Id"
      param :form, :first_name, :string, :optional, "First name"
      param :form, :last_name, :string, :optional, "Last name"
      param :form, :active, :boolean, :optional, "Active"
      response :not_found
      response :not_acceptable
    end

    # Lastly destroy is just like the rest and just takes in the param path for child id. 
    swagger_api :destroy do
      summary "Deletes an existing Child"
      param :path, :id, :integer, :required, "Child Id"
      response :not_found
    end


    # Controller Code

    before_action :set_child, only: [:show, :update, :destroy]

    # GET /children
    def index
      @children = Child.all
      if(params[:active].present?)
        @children = params[:active] == "true" ? @children.active : @children.inactive
      end

      if params[:alphabetical].present? && params[:alphabetical] == "true"
        @children = @children.alphabetical
      end

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
        render json: @child, status: :created, location: [:v1, @child]
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
end