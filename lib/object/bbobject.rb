module BBLib

  def self.to_hash obj
    return {obj => nil} unless !obj.instance_variables.empty?
    hash = {}
    obj.instance_variables.each do |var|
      value = obj.instance_variable_get(var)
      if value.is_a? Array
        hash[var.to_s.delete("@")] = value.map{ |v| v.respond_to?(:obj_to_hash) && !v.instance_variables.empty? ? v.obj_to_hash : v }
      elsif value.is_a? Hash
        begin
          if !hash[var.to_s.delete("@")].is_a?(Hash) then hash[var.to_s.delete("@")] = Hash.new end
        rescue
          hash[var.to_s.delete("@")] = Hash.new
        end
        value.each do |k, v|
          hash[var.to_s.delete("@")][k.to_s.delete("@")] = v.respond_to?(:obj_to_hash) && !v.instance_variables.empty? ? v.obj_to_hash : v
        end
      elsif value.respond_to?(:obj_to_hash) && !value.instance_variables.empty?
        hash[var.to_s.delete("@")] = value.obj_to_hash
      else
        hash[var.to_s.delete("@")] = value
      end
    end
    return hash
  end

end
