# Seeka

Seeka provides you with a solution to easily offer users the
ability to filter and search for things.

![Screenshot](https://s.adamcooke.io/15/mSTriw.png)

This is still very much in development as part of a new project
I'm working on. It provides a Ruby interface to define which fields
are available for searching and a javascript UI to allow users to
use it. You can also store saved filters as JSON.

Here's an example of a definition. This definition can then be
used to generate the inputs shown in the screenshot above.

```ruby
definition = Seeka::Definition.new
definition.base = self.contacts

definition.group 'Contact' do |fields|
  fields << Seeka::DefinitionField.new(:first_name)
  fields << Seeka::DefinitionField.new(:last_name)
  fields << Seeka::DefinitionField.new(:organisation_name)
  fields << Seeka::DefinitionField.new(:contact_type, :input_type => 'selection', :select_options => ['Person', 'Organisation'] )
  fields << Seeka::DefinitionField.new(:job_title)
  fields << Seeka::DefinitionField.new(:background)
  fields << Seeka::DefinitionField.new(:created_at, :value_transmogrification => :chronic)
  fields << Seeka::DefinitionField.new(:updated_at, :value_transmogrification => :chronic)
  fields << Seeka::DefinitionField.new(:hours_since_creation, :field => :created_at, :transmogrification => :timestamp_to_hours)
  fields << Seeka::DefinitionField.new(:days_since_creation, :field => :created_at, :transmogrification => :timestamp_to_days)
  fields << Seeka::DefinitionField.new(:status, :field => {:status => :name}, :input_type => 'selection', :select_options => self.contact_statuses.enabled.pluck(:name) )
end

definition.group 'Custom Fields' do |fields|
  self.custom_fields.asc.each do |cf|
    case cf.storage_type.to_sym
    when :datetime
      value_transmogification = :chronic
    when :date
      value_transmogification = :chronic_date
    else
      value_transmogification = nil
    end
    fields << Seeka::DefinitionField.new("custom_#{cf.id}".to_sym, :value_transmogrification => value_transmogification, :label => cf.label, :field => "#{cf.storage_type}_value", :foreign_key => :contact_id, :base => self.contact_custom_fields.where(:custom_field_id => cf.id))
  end
end

definition.group 'Product' do |fields|
  fields << Seeka::DefinitionField.new(:number_of_products, :condition => Seeka::Conditions::RelationCounter, :relationship => :products)
  fields << Seeka::DefinitionField.new(:product, :condition => Seeka::Conditions::HasMany, :field => {:products => :meta_product_id}, :input_type => 'selection', :select_options => self.products.enabled.pluck(:id, :name))
  fields << Seeka::DefinitionField.new(:product_description, :condition => Seeka::Conditions::HasMany, :field => {:products => :description})
  fields << Seeka::DefinitionField.new(:product_value, :condition => Seeka::Conditions::HasMany, :field => {:products => :value})
  fields << Seeka::DefinitionField.new(:product_status, :condition => Seeka::Conditions::HasMany, :field => {:products => :meta_product_link_status_id}, :input_type => 'selection', :select_options => self.product_link_statuses.enabled.pluck(:id, :name))
  fields << Seeka::DefinitionField.new(:product_started_on, :condition => Seeka::Conditions::HasMany, :field => {:products => :started_at})
  fields << Seeka::DefinitionField.new(:product_stopped_on, :condition => Seeka::Conditions::HasMany, :field => {:products => :stopped_at})
end

definition.group 'Notes' do |fields|
  fields << Seeka::DefinitionField.new(:number_of_notes, :condition => Seeka::Conditions::RelationCounter, :relationship => :notes)
end

definition.group 'Contact Methods' do |fields|
  fields << Seeka::DefinitionField.new(:number_of_contact_methods, :condition => Seeka::Conditions::RelationCounter, :relationship => :contact_methods)
  fields << Seeka::DefinitionField.new(:email_address, :field => :data1, :foreign_key => :contact_id, :base => self.contact_methods.where(:meta_contact_method_types => {:method_type => 'email'}).includes(:contact_method_type).references(:contact_method_type))
  fields << Seeka::DefinitionField.new(:phone_number, :field => :data1, :foreign_key => :contact_id, :base => self.contact_methods.where(:meta_contact_method_types => {:method_type => 'phone'}).includes(:contact_method_type).references(:contact_method_type))
  fields << Seeka::DefinitionField.new(:twitter, :field => :data1, :foreign_key => :contact_id, :base => self.contact_methods.where(:meta_contact_method_types => {:method_type => 'twitter'}).includes(:contact_method_type).references(:contact_method_type))
  fields << Seeka::DefinitionField.new(:address, :field => [:data1, :data2, :data3, :data4], :foreign_key => :contact_id, :base => self.contact_methods.where(:meta_contact_method_types => {:method_type => 'address'}).includes(:contact_method_type).references(:contact_method_type))
  fields << Seeka::DefinitionField.new(:postcode, :field => :data5, :foreign_key => :contact_id, :base => self.contact_methods.where(:meta_contact_method_types => {:method_type => 'address'}).includes(:contact_method_type).references(:contact_method_type))
  fields << Seeka::DefinitionField.new(:country, :field => :data6, :foreign_key => :contact_id, :base => self.contact_methods.where(:meta_contact_method_types => {:method_type => 'address'}).includes(:contact_method_type).references(:contact_method_type))
end
```

### Initializing Seeker

In your JavaScript, you’ll need to pass a number of paramaters to `Seeka.Form`.

##### `definition` - Object _(required)_

**An object representing the various filter conditions.**

If you use the view helper, Seeka will automatically populate a `<script>` tag with an ID of `seekaDefinitionJSON` in JSON.

##### `form` - jQuery _(required)_

**A jQuery object of the form object which contains the filters.**

If you don’t pass a class name into the view helper, the form will be given the class `.seeka__form` by default.

##### `query` - Object _(optional)_

**An object representing the exisiting filter conditions.**

If you use the view helper, Seeka will automatically populate a `<script>` tag with an ID of `seekaQueryJSON` in JSON.

##### `classNames` - Object _(optional)_

**Customise the names given to each UI component generated by Seeka.**

Simply pass in an object with the UI object, and the class name that should be used. You can override the following classes:

- addConditionGroup
- column
- conditionGroup
- fieldSelect
- fieldSelectInput
- input
- legend
- operatorSelect
- operatorSelectInput
- queryInput
- row
- searchButton
- select
- valueField

### Example Implementation

```coffeescript
$form = $('.js-advanced-query__form')

if $form.length

  $definitionJson = $('#seekaDefinitionJSON')

  if $definitionJson.length
    seekaDefinition = JSON.parse($definitionJson.text())

    if seekaDefinition?

      $queryJson = $('#seekaQueryJSON')

      if $queryJson.length
        seekaQuery = JSON.parse($queryJson.text())

      instance = new Seeka.Form
        form: $form
        definition: seekaDefinition
        query: seekaQuery
```

Further documentation will be provided as this project progresses.
