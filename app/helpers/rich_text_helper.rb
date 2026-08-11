# frozen_string_literal: true

# Sanitizes rich-text HTML authored via the admin/ui/_richtext editor.
# Belt-and-suspenders: SprintFeature already sanitizes on save; this
# sanitizes again at render time so display never trusts stored HTML blindly.
module RichTextHelper
  def sanitized_rich_text(html)
    sanitize(html.to_s, tags: SprintFeature::ALLOWED_TAGS, attributes: SprintFeature::ALLOWED_ATTRIBUTES)
  end
end
