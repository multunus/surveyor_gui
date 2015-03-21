module SurveyorGui
  module SurveyformsHelper
    require 'deep_cloneable'

    def list_dependencies(o)
      controlling_questions = o.controlling_questions

      controlling_question_ids = controlling_questions.map{|q| q.question_number.to_s+')'}.uniq
      count = controlling_question_ids.count
      retstr ='This question is shown depending on the '
      retstr += 'answer'.pluralize(count)
      retstr += ' to '
      retstr += 'question'.pluralize(count) + ' '
      retstr + list_phrase(controlling_question_ids)
    end

    def list_phrase(args)
      ## given a list of word parameters, return a syntactically correct phrase
      ## [dog] = "dog"
      ## [dog, cat] = "dog and cat"
      ## [dog, cat, bird] = "dog, cat and bird"
      case args.count
      when 0
        ''
      when 1
        args[0]
      when 2
        args[0] + ' and ' + args[1]
      else
        last = args.count
        args.take(last - 2).join(', ') + ', ' + args[last - 2] + ' and ' + args[last - 1]
      end
    end

    def render_questions_and_groups_helper(q, ss)
      #this method will render either a question or a complete question group.
      #we always iterate through questions, and if we happen to notice a question
      #belongs to a group, we process the group at that time.
      #note that questions carry a question_group_id, and this is how we know
      #that a question is part of a group, and that it should not be rendered individually,
      #but as part of a group.
      if q.object.part_of_group?
        _render_initial_group(q, ss)  ||  _respond_to_a_change_in_group_id(q, ss)
      else
        render "question_wrapper", f: q
      end
    end

    def render_one_group(qg)
      qg.simple_fields_for :questions, @current_group.questions do |f|
        if f.object.is_comment != true
          render "question_group_fields", f: f
        elsif f.object.is_comment == true
          "</div>".html_safe+(render "question_field", f: f)+"<div>".html_safe
        end
      end
    end

    def question_group_heading(f)
      if f.object.question_type_id == :grid_dropdown
        heading = f.object.question_group.columns
      elsif f.object.question_group.display_type == "grid"
        heading = f.object.answers
      else
        heading = []
      end
      heading.map {|a| "<span class=\"question_group_heading #{f.object.question_type_id.to_s}\" >#{a.text}<\/span>"}.join().html_safe
    end

    def row_label_if_question_group(question)
      if question.part_of_group?
        "<span class=\"row_name\">#{question.text}: </span>".html_safe
      end
    end

    def question_group_class(question)
      if @current_group.question_group.display_type == "inline"
        "inline"
      elsif @current_group.question_group.display_type == "default"
        "default"
      else
        if question.question_type_id == :grid_dropdown
          "dropdown"
        else
          "grid"
        end
      end
    end

    private
    def _render_initial_group(q, ss)
      if @current_group.nil?
        @current_group = QuestionGroupTracker.new(q.object.question_group_id)
        render "question_group", :ss => ss, :f => q
      end
    end

    def _respond_to_a_change_in_group_id(q, ss)
      if @current_group.question_group_id != q.object.question_group_id
        @current_group = QuestionGroupTracker.new(q.object.question_group_id)
        render "question_group", :ss => ss, :f => q
      end
    end
  end
end
