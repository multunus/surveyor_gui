module SurveyorGui
  module Models
    module ResponseMethods

      def self.included(base)
        base.send :has_many, :answers, :primary_key => :answer_id, :foreign_key => :id
        base.send :has_many, :questions
        base.send :belongs_to, :column
        base.send :attr_accessible, :response_set, :question, :answer, :date_value, :time_value,
            :response_set_id, :question_id, :answer_id, :datetime_value, :integer_value, :float_value,
            :unit, :text_value, :string_value, :response_other, :response_group,
            :survey_section_id, :blob, :column, :signature if defined? ActiveModel::MassAssignmentSecurity
        #belongs_to :user

        # after_destroy :delete_blobs!
        # after_destroy :delete_empty_dir
        base.send :before_save, :generate_signature_image

        #extends response to allow file uploads.
        base.send :mount_uploader, :blob, BlobUploader
        base.send :mount_uploader, :signature_image, SignatureUploader
      end

      VALUE_TYPE = ['float', 'integer', 'string', 'datetime', 'text']

      def response_value
        response_class = self.answer.response_class
        if self.question.pick=='none'
          _no_pick_value(response_class)
        else
          if self.answer.data_export_identifier == 'other'
            self.string_value
          else
            return self.answer.text
          end
        end
      end

      def is_comment?
        if self.answer
          self.answer.is_comment?
        else
          false
        end
      end

      def generate_signature_image
        unless self.signature.nil?
          instructions = JSON.load(self.signature).map { |h| "line #{h['mx']},#{h['my']} #{h['lx']},#{h['ly']}" } * ' '
          path_signature_image= 'tmp/'+"#{self.ip_address}_#{self.response_set_id}_"+DateTime.now.to_s+".png"
          system "convert -size 300x65 xc:transparent -stroke black -draw '#{instructions}' #{path_signature_image}"
          self.signature_image = File.open(path_signature_image)
          delete_temp_file(path_signature_image)
        end
      end

    private

      def delete_temp_file(file)
        FileUtils.rm(file)
      end

      def delete_blobs!
          self.remove_blob!
      end


      def delete_empty_dir
        FileUtils.rm_rf(File.join(Rails.root.to_s,'public',BlobUploader.store_dir))
        FileUtils.rm_rf(File.join(Rails.root.to_s,'public',SignatureUploader.store_dir))
      end

      def _no_pick_value(response_class)
        VALUE_TYPE.each do |value_type|
          value_attribute = value_type+'_value'
          if instance_eval(value_attribute)
            if response_class == "time"
              return self.datetime_value - self.datetime_value.beginning_of_day
            else
              return instance_eval(value_attribute)
            end
          end
        end
        nil
      end
    end
  end
end
