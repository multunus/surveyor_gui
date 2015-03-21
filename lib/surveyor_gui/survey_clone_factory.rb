module SurveyorGui
  class SurveyCloneFactory
    def initialize(id, as_template=false)
      @survey = Surveyform.find(id.to_i)
      @as_template = as_template
    end

    def clone
      cloned_survey = _deep_clone
      _set_api_keys(cloned_survey)
      if cloned_survey.save!
        return cloned_survey
      else
        raise cloned_survey.errors.messages.map{|m| m}.join(',')
        return nil
      end
    end

    def deep_clonable_attributes
      {
        sections:
        {
          questions: [
                      :answers,
                      {
                        dependency: {
                          dependency_conditions: [:question, :answer]
                        }
                      },
                      {
                        question_group: :columns
                      }
                     ]
        }
      }
    end

    private

    def _initial_clone
      initial_clone = @survey
      initial_clone.api_id = Surveyor::Common.generate_api_id
      initial_clone.survey_version = Survey.where(access_code: @survey.access_code).maximum(:survey_version) + 1
      return initial_clone
    end

    def _deep_clone
      _initial_clone.deep_clone include: deep_clonable_attributes, use_dictionary: true
    end

    def _set_api_keys(cloned_survey)
      cloned_survey.sections.each do |section|
        section.questions.each do |question|
          question.api_id = Surveyor::Common.generate_api_id
          question.question_group.api_id = Surveyor::Common.generate_api_id if question.part_of_group?
          question.answers.each do |answer|
            answer.api_id = Surveyor::Common.generate_api_id
          end
        end
      end
    end
  end
end
