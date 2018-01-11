module Api::V2  
  class ChoreChildSerializer < ActiveModel::Serializer
    attributes :id, :name, :points_earned, :active
  end
end
