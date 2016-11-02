# frozen_string_literal: true
require_relative 'attr'
require_relative 'hooks'

module BBLib
  def self.are_all?(klass, *vars)
    vars.all? { |var| var.is_a?(klass) }
  end

  def self.is_a?(obj, *klasses)
    klasses.any? { |klass| obj.is_a?(klass) }
  end

  def self.to_hash(obj)
    return { obj => nil } if obj.instance_variables.empty?
    hash = {}
    obj.instance_variables.each do |var|
      value = obj.instance_variable_get(var)
      if value.is_a?(Array)
        hash[var.to_s.delete('@')] = value.map { |v| v.respond_to?(:obj_to_hash) && !v.instance_variables.empty? ? v.obj_to_hash : v }
      elsif value.is_a?(Hash)
        begin
          unless hash[var.to_s.delete('@')].is_a?(Hash) then hash[var.to_s.delete('@')] = {} end
        rescue
          hash[var.to_s.delete('@')] = {}
        end
        value.each do |k, v|
          hash[var.to_s.delete('@')][k.to_s.delete('@')] = v.respond_to?(:obj_to_hash) && !v.instance_variables.empty? ? v.obj_to_hash : v
        end
      elsif value.respond_to?(:obj_to_hash) && !value.instance_variables.empty?
        hash[var.to_s.delete('@')] = value.obj_to_hash
      else
        hash[var.to_s.delete('@')] = value
      end
    end
    hash
  end

  def self.named_args(*args)
    args.last.is_a?(Hash) && args.last.keys.all? { |k| k.is_a?(Symbol) } ? args.last : {}
  end

  def self.named_args!(*args)
    if args.last.is_a?(Hash) && args.last.keys.all? { |k| k.is_a?(Symbol) }
      args.delete_at(-1)
    else
      {}
    end
  end
end
