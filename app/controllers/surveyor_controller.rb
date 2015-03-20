class SurveyorController < ApplicationController
  include Surveyor::SurveyorControllerMethods
  include SurveyorGui::SurveyorControllerCustomMethods
end
