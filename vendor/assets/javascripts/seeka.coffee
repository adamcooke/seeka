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
  fields: []

  #
  # Boolean to determine whether or not the Seeka has been setup.
  #
  initialized: false

  classNames:
    addConditionGroup: 'seeka__addConditionGroup'
    column: null
    conditionGroup: 'seeka__conditionGroup'
    fieldSelect: 'seeka__fieldSelect'
    fieldSelectInput: 'seeka__fieldSelectInput'
    input: null
    legend: null
    operatorSelect: 'seeka__operatorSelect'
    operatorSelectInput: 'seeka__operatorSelectInput'
    queryInput: 'seeka__queryInput'
    row: null
    searchButton: 'seeka__searchButton'
    select: null
    valueField: 'seeka__valueField'

  #
  # The name of the field to submit
  #
  fieldName: 'query'

  constructor: ({@definition, @form, @query, classNames} = {}) ->
    @query ?= {}
    $.extend(@classNames, classNames) if classNames?
    @setup()

  #
  # Build a new instance of a search form by setting up all the markup
  # as nessessary.
  #
  setup: (position) ->

    return console.error('#setup called on a Seeker instance that has already been initailized') if @initialized

    @fields = $.map @definition.fields, (f)-> f[1]

    # Create the new form container with the submit button
    if @form.get(0).tagName == 'FORM'
      @form.on 'submit', @onSubmit.bind(@)

      @form
        .append(
          $ '<input />',
            'class': @classNames.queryInput
            name: @fieldName
            type: 'hidden'
        )
        .append(
          $('<p />')
            .append(
              $ '<input />',
                'class': @classNames.searchButton
                name: 'search'
                type: 'submit'
                value: 'Search'
            )
          )
    else
      @form.parents('form').on 'submit', @onSubmit.bind(@)


      @form.append(
        $ '<input />',
          'class': @classNames.queryInput
          name: @fieldName
          type: 'hidden'
      )

    # Insert some buttons
    @form.prepend(
      $('<p />', { 'class': @classNames.addConditionGroup })
        .append(
          $('<a />', { href: '#', text: 'Add condition group' })
            .attr('data-behavior', 'seekaAddConditionGroup')
        )
    )

    $('a[data-behavior=seekaAddConditionGroup]', @form).on 'click', =>
      conditionGroup = @addConditionGroup(@)
      @addEmptyCondition(conditionGroup)
      false

    # Initial set up of the form
    if Object.getOwnPropertyNames(@query).length
      # We have a query
      @setupFromQuery()
    else
      # We don't have a query
      $group = @addConditionGroup()
      @addEmptyCondition($group)


  #
  # Add a condition group to the form
  #
  addConditionGroup: (initialType = 'all') ->
    $select = @conditionGroupTypeSelector(initialType)

    $group = $('<fieldset />', { 'class': @classNames.conditionGroup })
    $legend = $("<legend>Match <span>#{$select}</span> of the conditions listed below</legend>")

    $legend.addClass(@classNames.legend) if @classNames.legend?

    $group.append($legend)
    $group.append($('<ul />'))

    $group.insertBefore $(".#{@classNames.addConditionGroup}", @form)
    $group

  #
  # Build a condition group type select box and set the value
  # as appropriate.
  #
  conditionGroupTypeSelector: (selectedValue = 'all') ->
    $select = $('<select />')

    if @classNames.select?
      $select.addClass(@classNames.select)

    $.each ['all', 'any'], (i, str) ->
      $option = $('<option />', text: str, value: str)
      $option.attr('selected', 'selected') if $option.val() == selectedValue
      $select.append($option)

    $select[0].outerHTML

  #
  # Build a new condition set for this form to the given condition group
  #
  addEmptyCondition: ($group, selectedField = null) ->
    $select = $('<select />', class: @classNames.fieldSelectInput)

    if @classNames.select?
      $select.addClass(@classNames.select)

    $select.append('<option />')

    $.each @definition.fields, (i, fields) ->
      [label, group] = fields

      $optgroup = $('<optgroup />', { label: label })

      $.each group, (j, field) ->
        $optgroup.append(
          $('<option />', { text: field.label, value: field.name })
        )

      $select.append($optgroup)

    if selectedField?
      $("[value='#{selectedField}']", $select).attr('selected', 'selected')

    $item = $('<li />')
    $span = $('<span />', {'class': @classNames.fieldSelect})

    $span.addClass(@classNames.column) if @classNames.column?

    $span.append($select)

    $item.addClass(@classNames.row) if @classNames.row?

    $('ul', $group).append($item.append($span))
    form = this
    $select.on 'change', -> form.onFieldChange.call(form, $(this))
    $item

  #
  # Add a new condition to the given group with the appropriate
  # values as shown
  #
  addExistingCondition: ($group, field, operator, value = null) ->
    $condition = @addEmptyCondition($group, field)

    fieldDefinition = (@fields.filter (f) -> f.name == field)[0]

    $condition
      .append @operatorSelector(fieldDefinition.operators, operator)
      .append @searchInputField(fieldDefinition, value)

  #
  # The method which is called when the user changes a field
  #
  onFieldChange: (link) ->
    $link = $(link)
    $container = $link.parents('li')
    $otherConditions = $link.parents('ul').find('li')

    $(">:not(span.#{@classNames.fieldSelect})", $container).remove()

    value = $link.val()

    if value.length
      fieldDefinition = (@fields.filter (f)-> f.name == value)[0]

      if fieldDefinition
        @operatorSelector(fieldDefinition.operators).appendTo($container)
        @searchInputField(fieldDefinition).appendTo($container)

      # If the last object isn't a blank one any more, let's add a spare
      # so it can be used
      if $otherConditions.length == 1 || $link.parents('ul').find("li:last .#{@classNames.operatorSelect}").length > 0
        @addEmptyCondition($link.parents('fieldset')[0])
    else
      # if we have more than one condition left, just remove this object,
      # we don't need it in the list any more
      if $otherConditions.length > 1
        $container.remove()

  #
  # Return an operator selection box for the passed operators
  #
  operatorSelector: (operators, selected = null) ->
    $select = $('<select />', { 'class': @classNames.operatorSelectInput })

    $select.addClass(@classNames.select) if @classNames.select?

    $.each operators, (i, operator) ->
      escapedLabel = $('<div />', { text: operator.label }).html()
      $select.append(
        $('<option />', { text: escapedLabel, value: operator.key })
      )

    if selected?
      $("option[value='#{selected}']", $select).attr('selected', 'selected')

    $span = $('<span />', { 'class': @classNames.operatorSelect })
    $span.append($select)
    $span.addClass(@classNames.column) if @classNames.column?
    $span

  #
  # Return the appropriate input box for the given field
  #
  searchInputField: (field, value = null)->
    switch field.input_type
      when "string"
        $input = $('<input />', {'class': @classNames.valueField, value: if value then value else ''})
        $input.addClass(@classNames.input) if @classNames.input?
        $span = $('<span />').append($input)
        $span.addClass(@classNames.column) if @classNames.column?
        $span
      when "selection"
        $select = $('<select />', { 'class': @classNames.valueField })
        $select.addClass(@classNames.select) if @classNames.select?

        $.each field.select_options, (i, option)->
          if typeof option == 'string'
            $option = $('<option />', { text: option, value: option })
          else
            $option = $('<option />', { text: option[1], value: option[0] })
          $select.append($option)

        $("option[value='#{value}']", $select).attr('selected', 'selected') if value?
        $span = $('<span />').append($select)
        $span.addClass(@classNames.column) if @classNames.column?
        $span

  #
  # Executed when the form is submitted
  #
  onSubmit: (e) ->

    # Remove any empty condition groups as these are not desirable
    $.each $('fieldset', @form), (i, condition) ->
      if $(condition).find('li').length <= 1
        condition.remove()
    # Insert the search JSON into the form
    json = @compileJSON()
    $("input[type='hidden'][class='#{@classNames.queryInput}']", @form).val(json)

  #
  # Compile some JSON for this query based on the values in the form.
  #
  compileJSON: ->
    jsonGroups = []
    $groups = $("fieldset", @form)

    $.each $groups, (i, group) =>
      groupObject = {}
      groupObject.type = $('legend select', group).val()
      groupObject.params = new Array

      $.each $('li', group), (j, $field) =>
        fieldValue = $("select.#{@classNames.fieldSelectInput}", $field).val()
        operatorValue = $("select.#{@classNames.operatorSelectInput}", $field).val()
        value = $("input.#{@classNames.valueField}, select.#{@classNames.valueField}", $field).val()

        if fieldValue && operatorValue && fieldValue.length && operatorValue.length
          params =
            name: fieldValue
            operator: operatorValue
            value: value
          console.log(params)
          groupObject.params.push(params)

      jsonGroups.push(groupObject)

    JSON.stringify({groups: jsonGroups})

  #
  # Set up a new form from a query
  #
  setupFromQuery: ->
    if @query.groups?
      $.each @query.groups, (i, group)=>
        if group.params?
          conditionGroup = @addConditionGroup(group.type)
          $.each group.params, (j, param)=>
            @addExistingCondition(conditionGroup, param.name, param.operator, param.value)
          @addEmptyCondition(conditionGroup)
        else
          # invalid group
    else
      # invalid
