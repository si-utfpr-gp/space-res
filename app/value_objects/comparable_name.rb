# A name reduced to its letters and digits, without case or accents, so "Bloco A", "bloco-a" and
# "BLOCO  A" compare as equal. Runs in Ruby because SQLite's LOWER() and NOCASE only fold ASCII
# letters and keep accents.
ComparableName = Data.define(:key) do
  def self.from(text)
    new(key: text.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase(:fold).gsub(/[^\p{Alnum}]/, ""))
  end

  def include?(other)
    key.include?(other.key)
  end
end
