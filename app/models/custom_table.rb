class CustomTable < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  has_many :custom_fields, dependent: :destroy
  has_many :custom_entities, dependent: :destroy
  has_one :custom_entity
  has_and_belongs_to_many :projects

  acts_as_nested_set

  store :settings, accessors: [:main_custom_field_id], coder: JSON

  scope :sorted, lambda { order("#{table_name}.name ASC") }

  scope :like, lambda {|arg|
    if arg.present?
      pattern = "%#{arg.to_s.strip}%"
      where("LOWER(name) LIKE LOWER(:p)", p: pattern)
    end
  }

  safe_attributes 'name', 'author_id', 'main_custom_field_id', 'project_ids', 'is_for_all'

  validates :name, presence: true, uniqueness: true

  acts_as_customizable

  def css_classes
    s = 'project'
    s << ' root' if root?
    s << ' child' if child?
    s << (leaf? ? ' leaf' : ' parent')
    s
  end

  def main_custom_field
    CustomField.find_by(id: main_custom_field_id) || custom_fields.first
  end

  def query(totalable_all: false)
    query = CustomEntityQuery.new(name: '_', custom_table_id: id)
    visible_cfs = custom_fields.visible.sorted
    query.column_names ||= visible_cfs.map {|i| "cf_#{i.id}"}
    if totalable_all
      query.totalable_names = visible_cfs.select(&:totalable?).map {|i| "cf_#{i.id}"}
    end
    query
  end

end
