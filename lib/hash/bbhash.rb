class Hash
    def deep_merge second, merge_arrays: true
        merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : (merge_arrays && Array === v1 && Array === v2 ? (v1 + v2) : v2) }
        self.merge(second, &merger)
    end
end
