# An example Backbone application contributed by
# [Jérôme Gravel-Niquet](http://jgn.me/). This demo uses a simple
# [LocalStorage adapter](backbone-localstorage.html)
# to persist Backbone models within your browser.
# 
# This [CoffeeScript](http://jashkenas.github.com/coffee-script/) variation has been provided by [Jason Giedymin](http://jasongiedymin.com/).
#
# Note: two things you will notice with my CoffeeScript are that I prefer to
# use four space indents and prefer to use `()` for all functions.

# Load the application once the DOM is ready, using a `jQuery.ready` shortcut.
$ ->
  ### QuizItem Model ###

  # Our basic **QuizItem** model has `answer`, `order`, and `done` attributes.
  class QuizItem extends Backbone.Model
  # Default attributes for the quizitem.
    defaults:
      question: "Unpopulated question"
      answer: "(Unanswered)"
      correctanswer: ""

    # Ensure that each quizitem created has `answer`.
    initialize: ->
      if !@get("answer")
        @set({ "answer": @defaults.answer })

    # Remove this QuizItem from *localStorage* and delete its view.
    clear: ->
      @destroy()
      @view.remove()

  ### QuizItem Collection ###

  # The collection of quizitems is backed by *localStorage* instead of a remote
  # server.
  class QuizItemList extends Backbone.Collection

  # Reference to this collection's model.
    model: QuizItem

    # Save all of the quizitem items under the `"quizitems"` namespace.
    localStorage: new Store("flexiontest")

    # We keep the QuizItems in sequential order, despite being saved by unordered
    # GUID in the database. This generates the next order number for new items.
    nextOrder: ->
      return 1 if !@length
      return @last().get('order') + 1

    # QuizItems are sorted by their original insertion order.
    comparator: (quizitem) ->
      return quizitem.get("order")

  ### QuizItem Item View ###

  # The DOM element for a quizitem item...
  class QuizItemView extends Backbone.View

  #... is a list tag.
    tagName: "li"

    # Cache the template function for a single item.
    template: _.template($("#item-template").html())

    # The DOM events specific to an item.
    events:
      "click div.quizitem-answer": "edit",
      "keypress .quizitem-input": "updateOnEnter"

    # The QuizItemView listens for changes to its model, re-rendering. Since there's
    # a one-to-one correspondence between a **QuizItem** and a **QuizItemView** in this
    # app, we set a direct reference on the model for convenience.
    initialize: ->
      @model.bind('change', this.render)
      @model.view = this


    # Re-render the answers of the quizitem item.
    render: =>
      this.$(@el).html(@template(@model.toJSON()))
      @setAnswer()
      return this

    setAnswer: ->
      answer = @model.get("answer")
      this.$(".quizitem-answer").text(answer)
      @input = this.$(".quizitem-input")
      if answer != @model.defaults.answer
        this.$(".quizitem-input[value=" + answer + ']').attr('checked', 'checked');
      #      @input.bind("blur", @close)
#      @input.val(answer)

    # Switch this view into `"editing"` mode, displaying the input field.
    edit: =>
      this.$(@el).addClass("editing")
      @input.focus()
      @input.bind("change", @close)
      return
    # Close the `"editing"` mode, saving changes to the quizitem.
    close: =>
      selectedAnswer = this.$(":checked").val()
      @model.save({ answer: selectedAnswer })
      $(@el).removeClass("editing")
      correctAnswerDisplay = $(@el).find('.quizitem-correctanswer')
      if selectedAnswer == @model.get("correctanswer")
        correctAnswerDisplay.addClass('isCorrect')
      else
        correctAnswerDisplay.addClass('isWrong')
      correctAnswerDisplay.fadeIn();
      return
    # If you hit `enter`, we're through editing the item.
    updateOnEnter: (e) =>
      @close() if e.keyCode is 13

    # Remove this view from the DOM.
    remove: ->
      $(@el).remove()

    # Remove the item, destroy the model.
    clear: () ->
      @model.clear()

  ### The Application ###

  # Our overall **AppView** is the top-level piece of UI.
  class AppView extends Backbone.View
  # Instead of generating a new element, bind to the existing skeleton of
  # the App already present in the HTML.
    el_tag = "#quizitemapp"
    el: $(el_tag)

    # Delegated events for creating new items, and clearing completed ones.
#    events:
#      "keypress #new-quizitem": "createOnEnter",
#      "click .quizitem-clear a": "clearCompleted"

    # At initialization we bind to the relevant events on the `QuizItems`
    # collection, when items are added or changed. Kick things off by
    # loading any preexisting quizitems that might be saved in *localStorage*.
    initialize: =>
      @input = this.$("#new-quizitem")

      QuizItems.bind("add", @addOne)
      QuizItems.bind("reset", @addAll)
      QuizItems.bind("all", @render)

      QuizItems.fetch()

    render: =>
      this.$('#quizitem-stats').html()

    # Add a single quizitem item to the list by creating a view for it, and
    # appending its element to the `<ul>`.
    addOne: (quizitem) =>
      view = new QuizItemView({model: quizitem})
      this.$("#quizitem-list").append(view.render().el)

    # Add all items in the **QuizItems** collection at once.
    addAll: =>
      QuizItems.each(@addOne)
      ;

    # Generate the attributes for a new QuizItem item.
    newAttributes: ->
      return {
      answer: @input.val(),
      order: QuizItems.nextOrder(),
      }

    # If you hit return in the main input field, create new **QuizItem** model,
    # persisting it to *localStorage*.
    createOnEnter: (e) ->
      return if (e.keyCode != 13)
      QuizItems.create(@newAttributes())
      @input.val('')

    # Clear all done quizitem items, destroying their models.
    clearCompleted: ->
      _.each(QuizItems.done(), (quizitem) ->
        quizitem.clear()
      )
      return false


  # Create our global collection of **QuizItems**.
  QuizItems = new QuizItemList()  #It is supposed to be possible to pass in a collection here but couldn't get it to work
  App = new AppView()
  if QuizItems.length is 0
    $.each([
      { "question": "Tim Berners-Lee invented the Internet.", "correctanswer": "true"},
      { "question": "Dogs are better than cats.", "correctanswer": "false"},
      { "question": "Winter is coming.", "correctanswer": "true"},
      { "question": "Internet Explorer is the most advanced browser on Earth.", "correctanswer": "false"}
    ], (i, q) ->
      QuizItems.create(q))
