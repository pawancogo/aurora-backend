# frozen_string_literal: true

# One-way digest for opaque tokens (refresh/verification/reset). We store only the
# digest so a database leak never exposes usable tokens.
module TokenDigest
  def self.digest(raw)
    Digest::SHA256.hexdigest(raw.to_s)
  end
end
