# Monkey patching for ActiveRecord::Base
class Object
  def self.lazy_calculate(*attrs)
    attrs.each do |attr|
      define_method(attr) do
        method_name = "calculate_#{attr}"
        if not self[attr]
          if self.respond_to? method_name
            self[attr] = self.send(method_name)
            self.save!
          else
            raise "You should create '#{method_name}' first!"
          end
        end
        return self[attr]
      end
    end
  end
end