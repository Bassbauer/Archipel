/*
 * TNViewProperties.j
 *
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


@import <Foundation/Foundation.j>

@import <AppKit/CPButton.j>
@import <AppKit/CPImage.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>

@import <StropheCappuccino/PubSub/TNPubSubController.j>
@import <StropheCappuccino/TNStropheContact.j>
@import <TNKit/TNSwipeView.j>

@import "TNContactsController.j"
@import "TNAvatarController.j"


/*! @ingroup archipelcore
    subclass of CPView that represent the bottom-left property panel.
    it allows to change nickname of a TNStropheContact and give informations about it.
*/
@implementation TNPropertiesController: CPObject
{
    @outlet CPButton                buttonViewVCardSwipe;
    @outlet CPButton                buttonEventSubscription;
    @outlet CPButton                buttonViewXMPPInfosSwipe;
    @outlet CPButton                entryAvatar;
    @outlet CPImageView             entryStatusIcon;
    @outlet CPImageView             imageVCardIcon;
    @outlet CPImageView             imageViewVCardPhoto;
    @outlet CPTextField             entryDomain;
    @outlet CPTextField             entryNode;
    @outlet CPTextField             entryResource;
    @outlet CPTextField             entryStatus;
    @outlet CPTextField             entryType;
    @outlet CPTextField             labelDomain;
    @outlet CPTextField             labelNode;
    @outlet CPTextField             labelResource;
    @outlet CPTextField             labelStatus;
    @outlet CPTextField             labelType;
    @outlet CPTextField             labelVCard;
    @outlet CPTextField             labelVCardCompany;
    @outlet CPTextField             labelVCardEmail;
    @outlet CPTextField             labelVCardFN;
    @outlet CPTextField             labelVCardLocality;
    @outlet CPTextField             labelVCardRole;
    @outlet CPTextField             labelVCardWebiste;
    @outlet CPView                  viewVCard;
    @outlet CPView                  viewXMPPInfos;
    @outlet CPView                  viewNicknameContainer;
    @outlet CPView                  viewVCardContainer;
    @outlet TNContactsController    contactsController;
    @outlet TNEditableLabel         entryName           @accessors(readonly);
    @outlet TNSwipeView             mainSwipeView;

    BOOL                            _enabled            @accessors(getter=isEnabled);
    BOOL                            _isCollapsed        @accessors(getter=isCollapsed);
    TNAvatarController              _avatarManager      @accessors(getter=avatarManager);
    TNPubSubController              _pubSubController   @accessors(property=pubSubController);
    TNStropheContact                _entity             @accessors(getter=entity);

    CPImage                         _groupUserImage;
    CPImage                         _pubsubDisabledImage;
    CPImage                         _pubsubImage;
    CPImage                         _unknownUserImage;
    CPNumber                        _height;
}


#pragma mark -
#pragma mark Initialization

/*! initialize some values on CIB awakening
*/
- (void)awakeFromCib
{
    var bundle = [CPBundle mainBundle],
        center = [CPNotificationCenter defaultCenter];

    _height                 = 180;
    _isCollapsed            = YES;
    _unknownUserImage       = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"user-unknown.png"]];
    _groupUserImage         = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"groups.png"] size:CPSizeMake(16,16)];
    _pubsubImage            = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"pubsub.png"]];
    _pubsubDisabledImage    = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"pubsub-disabled.png"]];

    [mainSwipeView setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Backgrounds/dark-bg.png"]]]];
    [viewVCard setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Backgrounds/paper-bg.png"]]]];
    [viewXMPPInfos setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Backgrounds/paper-bg.png"]]]];

    [mainSwipeView setViews:[viewXMPPInfos, viewVCard]];

    var gradColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Backgrounds/background-nickname.png"]]];
    [viewNicknameContainer setBackgroundColor:gradColor];
    [viewVCardContainer setBackgroundColor:gradColor];

    [imageVCardIcon setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"vcard-icon.png"]]];

    [labelVCard setFont:[CPFont boldSystemFontOfSize:13]];
    [labelVCard setTextColor:[CPColor colorWithHexString:@"576066"]];
    [labelVCard setValue:[CPColor colorWithHexString:@"f4f4f4"] forThemeAttribute:@"text-shadow-color"];
    [labelVCard setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset"];
    [labelVCard setLineBreakMode:CPLineBreakByTruncatingTail];

    [entryName setFont:[CPFont boldSystemFontOfSize:13]];
    [entryName setTextColor:[CPColor colorWithHexString:@"576066"]];
    [entryName setTarget:self];
    [entryName setAction:@selector(changeNickName:)];
    [entryName setToolTip:CPLocalizedString(@"Click here to change the displayed named of the current contact or group", @"Click here to change the displayed named of the current contact or group")];
    [entryName setValue:[CPColor colorWithHexString:@"f4f4f4"] forThemeAttribute:@"text-shadow-color"];
    [entryName setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset"];
    [entryName setLineBreakMode:CPLineBreakByTruncatingTail];

    [labelResource setTextColor:[CPColor blackColor]];
    [labelStatus setTextColor:[CPColor blackColor]];
    [labelType setTextColor:[CPColor blackColor]];
    [labelDomain setTextColor:[CPColor blackColor]];
    [labelNode setTextColor:[CPColor blackColor]];

    [entryNode setSelectable:YES];
    [entryNode setLineBreakMode:CPLineBreakByTruncatingTail];

    [entryAvatar setBordered:NO];
    [entryAvatar setAutoresizingMask:CPViewMaxXMargin | CPViewMinXMargin];
    [entryAvatar setImageScaling:CPScaleProportionally];
    [entryAvatar setImage:_unknownUserImage];
    [entryAvatar setToolTip:CPLocalizedString(@"Click here to choose the avatar of the current contact (this only works with Archipel contacts, not users)", @"Click here to choose the avatar of the current contact (this only works with Archipel contacts, not users)")];

    [buttonEventSubscription setToolTip:@"Click on avatar to change it."];
    [buttonEventSubscription setBordered:NO];
    [buttonEventSubscription setImageScaling:CPScaleProportionally];
    [buttonEventSubscription setHidden:YES];

    [entryResource setToolTip:CPLocalizedString(@"The resource of the contact", @"The resource of the contact")];
    [entryDomain setToolTip:CPLocalizedString(@"The domain (XMPP server) of the contact", @"The domain (XMPP server) of the contact")];
    [entryStatus setToolTip:CPLocalizedString(@"The current status of the contact", @"The current status of the contact")];
    [entryType setToolTip:CPLocalizedString(@"The type of contact (hypervisor, virtual machine or user)", @"The type of contact (hypervisor, virtual machine or user)")];

    [imageViewVCardPhoto setImageScaling:CPScaleProportionally];

    [center addObserver:self selector:@selector(changeNickNameNotification:) name:CPTextFieldDidBlurNotification object:entryName];

    var imageArrowLeft = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"buttonArrows/button-arrow-left.png"] size:CPSizeMake(14.0, 14.0)],
        imageArrowLeftPressed = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"buttonArrows/button-arrow-pressed-left.png"] size:CPSizeMake(14.0, 14.0)],
        imageArrowRight = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"buttonArrows/button-arrow-right.png"] size:CPSizeMake(14.0, 14.0)],
        imageArrowRightPressed = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"buttonArrows/button-arrow-pressed-right.png"] size:CPSizeMake(14.0, 14.0)];

    [buttonViewXMPPInfosSwipe setTarget:mainSwipeView];
    [buttonViewXMPPInfosSwipe setBordered:NO];
    [buttonViewXMPPInfosSwipe setAction:@selector(nextView:)];
    [buttonViewXMPPInfosSwipe setImage:imageArrowRight]; // this avoid the blinking..
    [buttonViewXMPPInfosSwipe setValue:imageArrowRight forThemeAttribute:@"image"];
    [buttonViewXMPPInfosSwipe setValue:imageArrowRightPressed forThemeAttribute:@"image" inState:CPThemeStateHighlighted];

    [buttonViewVCardSwipe setTarget:mainSwipeView];
    [buttonViewVCardSwipe setBordered:NO];
    [buttonViewVCardSwipe setAction:@selector(nextView:)];
    [buttonViewVCardSwipe setImage:imageArrowLeft]; // this avoid the blinking..
    [buttonViewVCardSwipe setValue:imageArrowLeft forThemeAttribute:@"image"];
    [buttonViewVCardSwipe setValue:imageArrowLeftPressed forThemeAttribute:@"image" inState:CPThemeStateHighlighted];

    [labelVCardCompany setLineBreakMode:CPLineBreakByTruncatingTail];
    [labelVCardEmail setLineBreakMode:CPLineBreakByTruncatingTail];
    [labelVCardFN setLineBreakMode:CPLineBreakByTruncatingTail];
    [labelVCardLocality setLineBreakMode:CPLineBreakByTruncatingTail];
    [labelVCardRole setLineBreakMode:CPLineBreakByTruncatingTail];
    [labelVCardWebiste setLineBreakMode:CPLineBreakByTruncatingTail];
}


#pragma mark -
#pragma mark Notification handlers

/*! message performed when contact update its presence in order to update information
*/
- (void)reload:(CPNotification)aNotification
{
    [self reload]
}

/*! triggered when contact change the nickname
    @param aNotification the notification
*/
- (void)changeNickNameNotification:(CPNotification)aNotification
{
    var roster = [[TNStropheIMClient defaultClient] roster];

    if (([_entity isKindOfClass:TNStropheContact]) && ([_entity nickname] != [entryName stringValue]))
    {
        [roster changeNickname:[entryName stringValue] ofContact:_entity];
    }
    else if (([_entity isKindOfClass:TNStropheGroup]) && ([_entity name] != [entryName stringValue]))
    {
        var defaults    = [CPUserDefaults standardUserDefaults],
            oldKey      = TNArchipelRememberOpenedGroup + [_entity name];

        [roster changeName:[entryName stringValue] ofGroup:_entity];

        [defaults removeObjectForKey:oldKey];
    }
}

#pragma mark -
#pragma mark Setters

- (void)setEntity:(id)anEntity
{
    var center      = [CPNotificationCenter defaultCenter],
        oldEntity   = _entity;

    if (oldEntity && [oldEntity isKindOfClass:TNStropheContact])
    {
        [center removeObserver:self name:TNStropheContactVCardReceivedNotification object:oldEntity];
        [center removeObserver:self name:TNStropheContactPresenceUpdatedNotification object:oldEntity];
    }

    _entity = anEntity;

    if (_entity && ([_entity isKindOfClass:TNStropheContact]))
    {
        [center addObserver:self selector:@selector(reload:) name:TNStropheContactVCardReceivedNotification object:_entity];
        [center addObserver:self selector:@selector(reload:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    }
}

- (void)setEnabled:(BOOL)shouldEnable
{
    _enabled = shouldEnable;
    [entryName setEnabled:shouldEnable];
}


#pragma mark -
#pragma mark Utilities

- (void)setAvatarManager:(TNAvatarManager)anAvatarManager
{
    _avatarManager = anAvatarManager;

    [entryAvatar setTarget:self];
    [entryAvatar setAction:@selector(openAvatarManager:)];
}

/*! hide the panel
*/
- (void)hideView
{
    if (_isCollapsed)
        return;

    _isCollapsed = YES;

    [[mainSwipeView superview] setPosition:[[mainSwipeView superview] bounds].size.height ofDividerAtIndex:0];
}

/*! show the panel
*/
- (void)showView
{
    if (!_isCollapsed)
        return;

    _isCollapsed = NO;

    [[mainSwipeView superview] setPosition:([[mainSwipeView superview] bounds].size.height - _height) ofDividerAtIndex:0];
    [[CPNotificationCenter defaultCenter] postNotificationName:TNArchipelPropertiesViewDidShowNotification object:self];

}

/*! reload the panel
*/
- (void)reload
{
    if (!_entity || !_enabled)
    {
        [self hideView];
        return;
    }

    if ([_entity isKindOfClass:TNStropheContact])
    {
        [labelResource setStringValue:CPLocalizedString(@"Resource", @"Resource")];
        [labelStatus setHidden:NO];
        [labelDomain setHidden:NO];
        [labelType setHidden:NO];
        [labelNode setHidden:NO];
        [entryNode setHidden:NO];
        [entryAvatar setHidden:NO];
        [entryType setHidden:NO];

        [buttonEventSubscription setHidden:NO];

        [entryStatusIcon setImage:[_entity statusIcon]];
        [entryName setStringValue:[_entity nickname]];
        [entryDomain setStringValue:[[_entity JID] domain]];
        [entryResource setStringValue:[[_entity resources] lastObject]];
        [entryStatus setStringValue:[_entity XMPPStatus]];
        [entryNode setStringValue:[[_entity JID] node]];

        switch ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[_entity vCard]])
        {
            case TNArchipelEntityTypeVirtualMachine:
                [entryType setStringValue:CPLocalizedString(@"Virtual machine", @"Virtual machine")];
                [buttonEventSubscription setHidden:NO];
                break;

            case TNArchipelEntityTypeHypervisor:
                [entryType setStringValue:CPLocalizedString(@"Hypervisor", @"Hypervisor")];
                [buttonEventSubscription setHidden:NO];
                break;

            default:
                [entryType setStringValue:CPLocalizedString(@"User", @"User")];
                [buttonEventSubscription setHidden:YES];
        }

        if ([_entity avatar])
            [entryAvatar setImage:[_entity avatar]];
        else
            [entryAvatar setImage:_unknownUserImage];

        if (_avatarManager)
            [_avatarManager setEntity:_entity];

        if ([_pubSubController nodeWithName:@"/archipel/" + [[_entity JID] bare] + @"/events"])
        {
            [buttonEventSubscription setImage:_pubsubImage];
            [buttonEventSubscription setToolTip:CPLocalizedString(@"You are registred to the entity events.", @"You are registred to the entity events.")];
        }
        else
        {
            [buttonEventSubscription setImage:_pubsubDisabledImage];
            [buttonEventSubscription setToolTip:CPLocalizedString(@"You are not registred to the entity events.", @"You are not registred to the entity events.")];
        }

        [labelVCardFN setStringValue:@""];
        [labelVCardLocality setStringValue:@""];
        [labelVCardCompany setStringValue:@""];
        [labelVCardRole setStringValue:@""];
        [labelVCardEmail setStringValue:@""]
        [labelVCardWebiste setStringValue:@""];
        [imageViewVCardPhoto setImage:nil];

        if ([_entity vCard])
        {
            var vCard = [_entity vCard];

            [buttonViewVCardSwipe setHidden:NO];

            [labelVCardFN setStringValue:[[[vCard firstChildWithName:@"FN"] text] capitalizedString]];
            [labelVCardLocality setStringValue:[[[vCard firstChildWithName:@"LOCALITY"] text] capitalizedString]];
            [labelVCardCompany setStringValue:[[[vCard firstChildWithName:@"ORGNAME"] text] capitalizedString]];
            [labelVCardRole setStringValue:[[[vCard firstChildWithName:@"TITLE"] text] capitalizedString]];
            [labelVCardEmail setStringValue:[[vCard firstChildWithName:@"USERID"] text]]
            [labelVCardWebiste setStringValue:[[vCard firstChildWithName:@"URL"] text]];
            [imageViewVCardPhoto setImage:[_entity avatar] || _unknownUserImage];
        }

    }
    else if ([_entity isKindOfClass:TNStropheGroup])
    {
        var population = ([_entity count] > 1) ? [_entity count] + CPLocalizedString(@" contacts in group", @" contacts in group") : [_entity count] +CPLocalizedString( @" contact in group",  @" contact in group");

        [labelResource setStringValue:CPLocalizedString(@"Contents", @"Contents")];
        [labelStatus setHidden:YES];
        [labelDomain setHidden:YES];
        [labelType setHidden:YES];
        [labelNode setHidden:YES];
        [entryNode setHidden:YES];
        [entryAvatar setHidden:YES];
        [entryType setHidden:YES];

        [buttonEventSubscription setHidden:YES];

        [entryStatusIcon setImage:_groupUserImage];
        [entryName setStringValue:[_entity name]];
        [entryDomain setStringValue:@""];
        [entryResource setStringValue:population];
        [entryStatus setStringValue:@""];

        [mainSwipeView slideToViewIndex:0];
        [buttonViewVCardSwipe setHidden:YES];
    }

    [self showView];
}


#pragma mark -
#pragma mark Actions

/*! opens the avatar manager window if any
    @param sender the sender
*/
- (IBAction)openAvatarManager:(id)sender
{
    if (_avatarManager && [[[TNStropheIMClient defaultClient] roster] analyseVCard:[_entity vCard]] != TNArchipelEntityTypeUser)
        [_avatarManager showWindow:sender];
}

/*! action sent by the TNEditableLabel when ok. Will blur it
    @param sender the sender
*/
- (IBAction)changeNickName:(id)sender
{
    [[mainSwipeView window] makeFirstResponder:[entryName previousResponder]];
}

/*! subscribe (unsubscribe) to (from) the entity pubsub if any
    @param aSender the sender
*/
- (IBAction)manageContactSubscription:(id)aSender
{
    if ([_pubSubController nodeWithName:@"/archipel/" + [[_entity JID] bare] + @"/events"])
        [contactsController unsubscribeToPubSubNodeOfContactWithJID:[_entity JID]];
    else
        [contactsController subscribeToPubSubNodeOfContactWithJID:[_entity JID]];

    [self reload];
}


@end