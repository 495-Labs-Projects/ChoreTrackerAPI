module Api::V2
  class ChoreTaskSerializer < ActiveModel::Serializer
    attributes :id, :name
  end
end
