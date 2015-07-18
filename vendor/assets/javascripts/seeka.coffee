window.Seeka ||= {}

class Seeka.Form

  #
  # Stores the definition for the search
  #
  definition: null

  #
  # Stores the query to display in the form
  #
  query: null

  #
  # Stores the form object once it has been build
  #
  form: null

  #
  # Store all fields for easy access
  #
  fields: new Array

  #
  # The name of the field to submit
  #
  fieldName: 'query'

  #
  # Build a new instance of a search form by setting up all the markup
  # as nessessary.
  #
  setup: (position)->

    this.fields = $.map this.definition.fields, (f)-> f[1]

    # Create the new form container with the submit button

    if this.form.get(0).tagName == 'FORM'
      this.form.on 'submit', => this.onSubmit.call(this)
      formFurniture = $("<input class='seeka__queryInput' type='hidden' name='#{this.fieldName}'><p><input type='submit' name='search' class='seeka__searchButton' value='Search' />")
    else
      this.form.parents('form').on 'submit', => this.onSubmit.call(this)
      formFurniture = $("<input class='seeka__queryInput' type='hidden' name='#{this.fieldName}'>")


    this.form.append(formFurniture)

    # Insert some buttons
    this.form.prepend("<p class='seeka__addConditionGroup'><a href='#' data-behavior='seekaAddConditionGroup'>Add condition group</a></p>")
    $('a[data-behavior=seekaAddConditionGroup]', this.form).on 'click', =>
      conditionGroup = this.addConditionGroup(this)
      this.addEmptyCondition(conditionGroup)

    # Initial set up of the form
    if Object.getOwnPropertyNames(this.query).length
      # We have a query
      this.setupFromQuery()
    else
      # We don't have a query
      group = this.addConditionGroup()
      this.addEmptyCondition(group)


  #
  # Add a condition group to the form
  #
  addConditionGroup: (initialType='all')->
    select = this.conditionGroupTypeSelector(initialType)
    conditionGroup = $("<fieldset class='seeka__conditionGroup'><legend>Match <span>#{select}</span> of the conditions listed below</legend><ul></ul></fieldset>")
    conditionGroup.insertBefore $('p.seeka__addConditionGroup', this.form)
    conditionGroup

  #
  # Build a condition group type select box and set the value
  # as appropriate.
  #
  conditionGroupTypeSelector: (selectedValue = 'all')->
    select = $("<select><option value='all'>all</option><option value='any'>any</option></select>")
    $("option[value='#{selectedValue}']", select).attr('selected', 'selected')
    select[0].outerHTML

  #
  # Build a new condition set for this form to the given condition group
  #
  addEmptyCondition: (conditionGroup, selectedField = null)->

    options = $.map this.definition.fields, (group, index)->
      opts = $.map group[1], (field, j)->
        "<option value='#{field.name}'>#{field.label}</option>"
      "<optgroup label='#{group[0]}'>#{opts.join('')}</optgroup>"

    fieldSelector = $("<select class='seeka__fieldSelectInput'><option></option>#{options.join('')}</select>")
    if selectedField
      $("option[value='#{selectedField}']", fieldSelector).attr('selected', 'selected')
    conditionParent = $("<li></li>").append("<span class='seeka__fieldSelect'></span>")
    conditionParent.find('span').append(fieldSelector)
    $('ul', conditionGroup).append(conditionParent)
    form = this
    fieldSelector.on 'change', -> form.onFieldChange.call(form, $(this))
    conditionParent

  #
  # Add a new condition to the given group with the appropriate
  # values as shown
  #
  addExistingCondition: (conditionGroup, field, operator, value = null)->
    conditionParent = this.addEmptyCondition(conditionGroup, field)
    fieldDefinition = (this.fields.filter (f)-> f.name == field)[0]
    $(this.operatorSelector(fieldDefinition.operators, operator)).appendTo(conditionParent)
    $(this.searchInputField(fieldDefinition, value)).appendTo(conditionParent)

  #
  # The method which is called when the user changes a field
  #
  onFieldChange: (link)->
    container = $(link).parents('li')
    otherConditions = $(link).parents('ul').find('li')

    $(">:not(span.seeka__fieldSelect)", container).remove()
    value = $(link).val()
    if value.length
      fieldDefinition = (this.fields.filter (f)-> f.name == value)[0]
      if fieldDefinition
        $(this.operatorSelector(fieldDefinition.operators)).appendTo(container)
        $(this.searchInputField(fieldDefinition)).appendTo(container)

      # If the last object isn't a blank one any more, let's add a spare so it can
      # be used
      if otherConditions.length == 1 || $(link).parents('ul').find("li:last select.seeka__operatorSelect").length > 0
        this.addEmptyCondition($(link).parents('fieldset')[0])
    else
      # if we have more than one condition left, just remove this object, we don't
      # need it in the list any more
      if otherConditions.length > 1
        container.remove()

  #
  # Return an operator selection box for the passed operators
  #
  operatorSelector: (operators, selected = null)->
    options = $.map operators, (op, index)->
      escapedLabel = $("<p></p>").text(op.label).html()
      "<option value='#{op.key}'>#{escapedLabel}</option>"
    select = $("<select class='seeka__operatorSelectInput'>#{options.join('')}</select>")
    if selected
      $("option[value='#{selected}']", select).attr('selected', 'selected')
    "<span class='seeka__operatorSelect'>#{select[0].outerHTML}</span>"

  #
  # Return the appropriate input box for the given field
  #
  searchInputField: (field, value = null)->
    switch field.input_type
      when "string"
        "<input class='seeka__valueField' value='#{if value then value else ''}'>"
      when "selection"
        options = $.map field.select_options, (opt, index)->
          if typeof opt == 'string'
            $("<option>#{opt}</option>").val(opt)[0].outerHTML
          else
            $("<option value='#{opt[0]}'>#{opt[1]}</option>").val(opt)[0].outerHTML

        select = $("<select class='seeka__valueField'>#{options.join('')}</select>")
        if value
          $("option[value='#{value}']", select).attr('selected', 'selected')
        "<span>#{select[0].outerHTML}</span>"

  #
  # Executed when the form is submitted
  #
  onSubmit: ->
    # Remove any empty condition groups as these are not desirable
    $.each $('fieldset', this.form), (i, conditionGroup)->
      if $(conditionGroup).find('li').length <= 1
        conditionGroup.remove()
    # Insert the search JSON into the form
    json = this.compileJSON()
    $('input[type=hidden][class=seeka__queryInput]', this.form).val(json)

  #
  # Compile some JSON for this query based on the values in the form.
  #
  compileJSON: ->
    jsonGroups = new Array
    conditionGroups = $("fieldset", this.form)
    $.each conditionGroups, (i, group)->
      groupObject = {}
      groupObject.type = $('legend select', group).val()
      groupObject.params = new Array
      $.each $("li", group), (j, field)->
        fieldValue = $('select.seeka__fieldSelectInput', field).val()
        operatorValue = $('select.seeka__operatorSelectInput', field).val()
        value = $('input.seeka__valueField, select.seeka__valueField', field).val()
        if fieldValue && operatorValue && fieldValue.length && operatorValue.length
          paramObject = {}
          paramObject.name = fieldValue
          paramObject.operator = operatorValue
          paramObject.value = value
          groupObject.params.push(paramObject)
      jsonGroups.push(groupObject)
    JSON.stringify({groups: jsonGroups})

  #
  # Set up a new form frmo a query
  #
  setupFromQuery: ->
    if this.query.groups?
      $.each this.query.groups, (i, group)=>
        if group.params?
          conditionGroup = this.addConditionGroup(group.type)
          $.each group.params, (j, param)=>
            this.addExistingCondition(conditionGroup, param.name, param.operator, param.value)
          this.addEmptyCondition(conditionGroup)
        else
          # invalid group
    else
      # invalid

$ ->
  if seekaDefinition? && $('form.seeka__form').length
    form = new Seeka.Form
    form.definition = seekaDefinition
    form.query = if seekaQuery? then seekaQuery else {}
    form.form = $('form.seeka__form')
    form.setup()
