module Api::V1  
  class ChoreTaskSerializer < ActiveModel::Serializer
    attributes :id, :name
  end
end
