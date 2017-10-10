class ChildSerializer < ActiveModel::Serializer
  attributes :id, :name, :points_earned, :active
  has_many :chores
end
