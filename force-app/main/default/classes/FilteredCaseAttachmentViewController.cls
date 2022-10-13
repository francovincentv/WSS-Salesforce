/**
 * For accessing attachments being referenced from a case.
 * This controller supports the FilteredCaseAttachmentView component by
 * implementing its model.
 *
  * $LastChangedDate: 2018-11-29 14:21:33 +0100 (Thu, 29 Nov 2018) $
 * $Rev: 24623 $
 * $Header$*
 */
public class FilteredCaseAttachmentViewController {

    /**
     * @param address the address to check
     *
     * @return true if the given address has wilhelmsen.com as domain
     */
    public static boolean isInternalAddress(String address) {
        return address != null && address.endsWith('@wilhelmsen.com');
    }

    /**
     * @param emailMessage the message to check
     *
     * @return true if either the to or the cc address has a domain of a non-wilhelmsen address
     */
    public static boolean isToExternalAddress(EmailMessage emailMessage) {
        return containsExternalAddress(emailMessage.ToAddress) || containsExternalAddress(emailMessage.CcAddress);
    }

    /**
     * @param addresses list of email addresses - expected to be separated by ;
     *
     * @return if one (or more) of the addresses are non-wilhelmsen.com
     */
    public static boolean containsExternalAddress(String addresses) {
        List<String> splitAddresses;

        if (addresses == null) {
            return false;
        }
        if (addresses.contains(';')) {
            splitAddresses = addresses.split(';');
        } else {
            splitAddresses = new List<String>();
            splitAddresses.add(addresses);
        }

        for (String address : splitAddresses) {
            if (!isInternalAddress(address.trim())) {
                return true;
            }

        }

        return false;
    }

    /**
     * For checking if an email can by classified as internal by having having only wilhelmsen.com in the
     * from, to and cc addresses
     *
     * @param emailMessage the message to check
     *
     * @return  true if all addresses are for wilhelmsen.com
     */
    public static boolean isOnlyInternalAddress(EmailMessage emailMessage) {
        return !isToExternalAddress(emailMessage) && isInternalAddress(emailMessage.FromAddress);
    }


    @AuraEnabled
    @TestVisible public static List<FilteredCaseAttachmentViewWrapper> getAttachments(Id recordId,
                                                                                      boolean fromCustomer,
                                                                                      boolean toCustomer,
                                                                                      boolean internal) {
        List<FilteredCaseAttachmentViewWrapper> attachmentsToView;
        List<FilteredCaseAttachmentViewWrapper> attachments;

        attachmentsToView = new List<FilteredCaseAttachmentViewWrapper>();

        attachments = getAttachmentsFromEmails(recordId,
                fromCustomer,
                toCustomer,
                internal);

        if (attachments != null) {
            attachmentsToView.addAll(attachments);
        }

        attachments = getAttachmentsFromCase(recordId,
                fromCustomer,
                toCustomer,
                internal);

        if (attachments != null) {
            attachmentsToView.addAll(attachments);
        }

        return attachmentsToView;


    }

    /**
     * Returns attachments associated with the case directly for the case having recordId
     *
     * @param recordId id of the case to lookup from
     * @param fromCustomer if true then include attachments created by the CBSLink user and being classified as from customer
     * @param toCustomer if true then include attachments created by the CBSLink user and being classified as to customer
     * @param internal if true then include attachments not being created by the CBSLink user
     *
     * @return list of attachments
     */
    @TestVisible private static List<FilteredCaseAttachmentViewWrapper> getAttachmentsFromCase(Id recordId,
                                                                                               boolean fromCustomer,
                                                                                               boolean toCustomer,
                                                                                               boolean internal) {
        List<Attachment> attachments;
        List<FilteredCaseAttachmentViewWrapper> attachmentsToView;

        attachmentsToView = new List<FilteredCaseAttachmentViewWrapper>();

        attachments = [select Id, Name, Description, CreatedDate, BodyLength, ContentType, CreatedBy.Name from Attachment where parentid = :recordId];

        for (Attachment attachment : attachments) {

            if (isFromCustomer(attachment)) {
                if (fromCustomer) {
                    attachmentsToView.add(wrap(attachment, 'From Customer'));
                }
                continue;

            }

            if (isToCustomer(attachment)) {
                if (toCustomer) {
                    attachmentsToView.add(wrap(attachment, 'To Customer'));
                }
                continue;
            }

            if (internal) {
                attachmentsToView.add(wrap(attachment, 'Internal'));
                continue;
            }

        }

        return attachmentsToView;

    }

    @TestVisible private static boolean isFromCustomer(Attachment attachment) {
        if (attachment.Name == null) {
            return null;
        }

        if (attachment.Name.startsWith('Buyers original')) {
            return true;
        }

        return false;
    }

    @TestVisible private static boolean isToCustomer(Attachment attachment) {
        if (attachment.Name == null) {
            return null;
        }

        if (attachment.Name.startsWith('From Quote')) {
            return true;
        }

        if (attachment.Name.startsWith('From Order Confirmation')) {
            return true;
        }

        return false;
    }


    /**
     * Returns the attachments from emails referenced by the case having recordId
     *
     * @param recordId id of the case to lookup from
     * @param fromCustomer if true include attachments from emails from the customer
     * @param toCustomer if true include attachments from emails to the customer
     * @param internal if true include attachments from emails to and from wilhelmsen only
     *
     * @return list of attachments
     */
    @TestVisible private static List<FilteredCaseAttachmentViewWrapper> getAttachmentsFromEmails(Id recordId,
                                                                                                 boolean fromCustomer,
                                                                                                 boolean toCustomer,
                                                                                                 boolean internal) {

        List<EmailMessage> emails;
        Set<Id> fromCustomerEmailIds;
        Set<Id> toCustomerEmailIds;
        Set<Id> internalEmailIds;

        List<FilteredCaseAttachmentViewWrapper> attachmentsToView;
        List<FilteredCaseAttachmentViewWrapper> attachmentsFound;

        emails = [select id, fromaddress, CcAddress, toaddress from EmailMessage where parentid = :recordId];

        fromCustomerEmailIds = new Set<Id>();
        toCustomerEmailIds = new Set<Id>();
        internalEmailIds = new Set<Id>();

        for (EmailMessage emailMessage : emails) {
            if (!isInternalAddress(emailMessage.fromaddress)) {
                fromCustomerEmailIds.add(emailMessage.id);
                continue;
            }

            if (isToExternalAddress(emailMessage)) {
                toCustomerEmailIds.add(emailMessage.id);
                continue;
            }

            if (isOnlyInternalAddress(emailMessage)) {
                internalEmailIds.add(emailMessage.id);
                continue;
            }
        }

        System.debug('Query for attachments of ' + recordId);
        attachmentsToView = new List<FilteredCaseAttachmentViewWrapper>();

        if (fromCustomer && fromCustomerEmailIds.size() > 0) {

            attachmentsFound = wrapAttachments(fromCustomerEmailIds, 'From Customer');
            if (attachmentsFound != null) {
                attachmentsToView.addAll(attachmentsFound);
            }
        }

        if (toCustomer && toCustomerEmailIds.size() > 0) {

            attachmentsFound = wrapAttachments(toCustomerEmailIds, 'To Customer');
            if (attachmentsFound != null) {
                attachmentsToView.addAll(attachmentsFound);
            }
        }

        if (internal && internalEmailIds.size() > 0) {

            attachmentsFound = wrapAttachments(internalEmailIds, 'Internal');
            if (attachmentsFound != null) {
                attachmentsToView.addAll(attachmentsFound);
            }
        }

        return attachmentsToView;
    }

    @TestVisible static List<FilteredCaseAttachmentViewWrapper> wrapAttachments(Set<Id> ids,
                                                                                String type) {
        List<FilteredCaseAttachmentViewWrapper> attachmentsFound;
        FilteredCaseAttachmentViewWrapper wrapper;
        List<Attachment> attachments;

        attachments = [select Id, Name, Description, CreatedDate, BodyLength, ContentType from Attachment where parentId = :ids];

        attachmentsFound = new List<FilteredCaseAttachmentViewWrapper>();

        for (Attachment attachment : attachments) {
            if (attachment.ContentType.equals('image/png') ||
            attachment.ContentType.equals('image/jpg') ) {
                if (attachment.BodyLength < 10000) {
                    continue;
                }
            }


            wrapper = wrap(attachment, type);

            attachmentsFound.add(wrapper);

        }


        return attachmentsFound;
    }

    @TestVisible static FilteredCaseAttachmentViewWrapper wrap(Attachment attachment,
                                                               String type) {
        FilteredCaseAttachmentViewWrapper wrapper;
        wrapper = new FilteredCaseAttachmentViewWrapper();
        wrapper.type = type;
        wrapper.Name = attachment.Name;
        wrapper.CreatedDate = attachment.CreatedDate;
        wrapper.Id = attachment.Id;

        return wrapper;
    }

}