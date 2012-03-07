class Diaspora::Federated::Validator::Private
  include ActiveModel::Validations

  attr_accessor :salmon, :user, :sender, :object

  validate :relayable_object_has_parent
  validate :contact_required
  validate :sender_is_someone_who_has_authority_of_the_post
  validate :model_is_valid?

  def initialize(salmon, user, sender)
    self.salmon = salmon
    self.user = user
    self.sender = sender
  end

  def process!
    return nil unless valid_signature_on_envelope? #parsing can be $$$ so do it first

    #may need to handle case where parse returns nil
    if self.valid?
      object 
    else
      #this is a hack to make tests pass for now
      raise self.errors.full_messages.join
      FEDERATION_LOGGER.info("Failed Private Receive: #{self.errors.inspect}")
      nil
    end
  end

  def object
    @object ||= Diaspora::Federated::Parser.new(salmon.parsed_data, sender).parse!
  end

  private

  #weird
  def valid_signature_on_envelope?
    if(sender.present? && !self.salmon.verified_for_key?(sender.public_key))
      return false
    else
      true
      #errors.add :salmon, "sender failed key check"
    end
  end

  # the diaspora handle of the person we expect to be sending us the message
  # if it is a relayable, the parent author is sending us the object
  # otherwise, it is the author of the thing itself(duh)
  def expected_object_authority
    if object.respond_to?(:relayable?)
      #if A and B are friends, and A sends B a comment from C, we delegate the validation to the owner of the post being commented on
      user.owns?(object.parent) ? object.diaspora_handle : object.parent.author.diaspora_handle #is this just trying save queries?
    else
      object.diaspora_handle
    end
  end

  #validations

  def relayable_object_has_parent
    if object.respond_to?(:relayable?) && object.parent.nil?
      errors.add :base, "Relayable Object has no known parent."
    end
  end

  def contact_required
    unless object.is_a?(Request) || user.contact_for(sender).present?
      errors.add :base, "Contact required to receive object."
    end
  end

  def sender_is_someone_who_has_authority_of_the_post
    unless sender.diaspora_handle == expected_object_authority
      errors.add :base, "Message sent from someone who does not have write access to the object"
    end
  end

  def model_is_valid?
    unless object.valid?
      errors.add :object, "#{object.class}: {object.errors.full_messages.join(', ')}"
    end
  end
end