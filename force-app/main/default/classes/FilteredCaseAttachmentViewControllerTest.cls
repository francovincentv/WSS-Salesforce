/*
 * $LastChangedDate: 2018-11-20 07:16:50 +0100 (Tue, 20 Nov 2018) $
 * $Rev: 24564 $
 * $Header$ *
 */
@isTest
public class FilteredCaseAttachmentViewControllerTest {
    @isTest static void testIsToExternalAddress(){
        EmailMessage emailMessage;

        emailMessage = new EmailMessage();
        emailMessage.ToAddress = 'marius.midtvik@gmail.com;marius.midtvik@wilhelmsen.com';
        System.assertEquals(true, FilteredCaseAttachmentViewController.isToExternalAddress(emailMessage));

        emailMessage = new EmailMessage();
        emailMessage.ToAddress = 'marius.midtvik@wilhelmsen.com';
        System.assertEquals(false, FilteredCaseAttachmentViewController.isToExternalAddress(emailMessage));

        emailMessage = new EmailMessage();
        emailMessage.ToAddress = 'marius.midtvik@gmail.com';
        System.assertEquals(true, FilteredCaseAttachmentViewController.isToExternalAddress(emailMessage));

    }

    @isTest static void testGetAttachmentsFromEmails() {
        Case caseObject;
        EmailMessage emailMessage;
        Attachment attachment;

        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';

        insert caseObject;


        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
        emailMessage.FromAddress = 'marius.midtvik@wilhelmsen.com';
        emailMessage.ToAddress = 'dummy@gmail.com';
        emailMessage.TextBody = 'BLA BLA XXX';
        emailMessage.ParentId = caseObject.ID;

        insert emailMessage;

        attachment = new Attachment();
        attachment.ContentType = 'application/pdf';
        attachment.Name = 'file.pdf';
        attachment.ParentId = emailMessage.Id;
        attachment.Body = EncodingUtil.base64Decode('X');
        insert attachment;

        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
        emailMessage.FromAddress = 'marius.midtvik@wilhelmsen.com';
        emailMessage.ToAddress = 'marius.midtvik@wilhelmsen.com';
        emailMessage.TextBody = 'BLA BLA XXX';
        emailMessage.ParentId = caseObject.ID;

        insert emailMessage;

        attachment = new Attachment();
        attachment.ContentType = 'application/pdf';
        attachment.Name = 'file.pdf';
        attachment.ParentId = emailMessage.Id;
        attachment.Body = EncodingUtil.base64Decode('X');
        insert attachment;
        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
        emailMessage.FromAddress = 'marius.midtvik@gmail.com';
        emailMessage.ToAddress = 'cs.singapore@wilhelmsen.com;dummy@gmail.com';
        emailMessage.TextBody = 'BLA BLA XXX';
        emailMessage.ParentId = caseObject.ID;

        insert emailMessage;

        attachment = new Attachment();
        attachment.ContentType = 'application/pdf';
        attachment.Name = 'file_out.pdf';
        attachment.ParentId = emailMessage.Id;
        attachment.Body = EncodingUtil.base64Decode('X');
        insert attachment;


        FilteredCaseAttachmentViewController.getAttachmentsFromEmails(caseObject.id, true, true, true);


    }

    @isTest static void testgetAttachmentsFromCase() {
        Case caseObject;
        Attachment attachment;
        Set<Id> ids;



        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';

        insert caseObject;

        attachment = new Attachment();
        attachment.ContentType = 'application/pdf';
        attachment.Name = 'From Quote - ';
        attachment.ParentId = caseObject.Id;
        attachment.Body = EncodingUtil.base64Decode('X');
        insert attachment;

        attachment = new Attachment();
        attachment.ContentType = 'application/pdf';
        attachment.Name = 'From Order Confirmation - ';
        attachment.ParentId = caseObject.Id;
        attachment.Body = EncodingUtil.base64Decode('X');
        insert attachment;

        attachment = new Attachment();
        attachment.ContentType = 'application/pdf';
        attachment.Name = 'Buyers original - ';
        attachment.ParentId = caseObject.Id;
        attachment.Body = EncodingUtil.base64Decode('X');
        insert attachment;

        attachment = new Attachment();
        attachment.ContentType = 'application/pdf';
        attachment.Name = 'Dummy';
        attachment.ParentId = caseObject.Id;
        attachment.Body = EncodingUtil.base64Decode('X');
        insert attachment;

        attachment = new Attachment();
        attachment.ContentType = 'image/png';
        attachment.Name = 'logo.png';
        attachment.ParentId = caseObject.Id;
        attachment.Body = EncodingUtil.base64Decode('X');
        insert attachment;

        FilteredCaseAttachmentViewController.getAttachmentsFromCase(caseObject.id, true, true, true);

        List<FilteredCaseAttachmentViewWrapper> wrapAttachments;
        ids = new Set<Id>();
        ids.add(caseObject.id);
        wrapAttachments = FilteredCaseAttachmentViewController.wrapAttachments(ids, 'Internal');
    }


    @isTest static void testIsFromCustomer() {
        Attachment attachment;

        attachment = new Attachment();
        attachment.Name = 'Buyers original - ';
        system.assert(FilteredCaseAttachmentViewController.isFromCustomer(attachment));

        attachment = new Attachment();
        attachment.Name = 'X';
        system.assert(!FilteredCaseAttachmentViewController.isFromCustomer(attachment));

        attachment = new Attachment();
        system.assert(null == FilteredCaseAttachmentViewController.isFromCustomer(attachment));
    }
    @isTest static void testIsToCustomer() {
        Attachment attachment;

        attachment = new Attachment();
        attachment.Name = 'From Quote - ';
        system.assert(FilteredCaseAttachmentViewController.isToCustomer(attachment));

        attachment = new Attachment();
        attachment.Name = 'From Order Confirmation - ';
        system.assert(FilteredCaseAttachmentViewController.isToCustomer(attachment));

        attachment = new Attachment();
        attachment.Name = 'X';
        system.assert(!FilteredCaseAttachmentViewController.isToCustomer(attachment));

        attachment = new Attachment();
        system.assert(null == FilteredCaseAttachmentViewController.isToCustomer(attachment));

    }
    @isTest static void testIsOnlyInternalAddress() {
        EmailMessage emailMessage;

        emailMessage = new EmailMessage();
        emailMessage.ToAddress = 'marius.midtvik@wilhelmsen.com';
        emailMessage.FromAddress = 'marius.midtvik@gmail.com;marius.midtvik@wilhelmsen.com';

        System.assertEquals(true, FilteredCaseAttachmentViewController.isOnlyInternalAddress(emailMessage));
    }

    @isTest static void testWrap() {
        FilteredCaseAttachmentViewWrapper wrapped;
        Attachment attachment;
        attachment = new Attachment();

        wrapped = FilteredCaseAttachmentViewController.wrap(attachment,
                'Internal');
        System.assert(wrapped != null);
    }

    @isTest static void testgetAttachments() {
        List<FilteredCaseAttachmentViewWrapper> attachments;
        Case caseObject;

        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';

        insert caseObject;

        attachments = FilteredCaseAttachmentViewController.getAttachments(caseObject.Id, false, false, false);
        System.assertEquals(0, attachments.size());
    }
}