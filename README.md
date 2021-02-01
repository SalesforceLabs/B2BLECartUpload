# _[B2B LE Cart Upload]_

#### _Enable users to add items to their cart using a text list or a CSV file_

#### Adding tens or hundreds of items to your cart is very time consuming. Even using the Quick Order widget requires many clicks to add just ten items. This component enables your users to add items to the cart with just a few clicks!

The B2B LE Cart Upload component enables users to add tens or hundreds of items to the cart with just a few clicks. Input can be in the form of a CSV file, or simply pasted into a text area within the component. The component verifies all items to be added using the product search API. Users can optionally check a box to ignore invalid SKUS during processing. Users can also optionally send a transcript of the upload results to their email address. The component also fully supports internationalization. You can add translations to the custom labels the component uses, so that all text within the component will be displayed in your user's local language.

<h4 align="center">
	<a href="#features">Features</a> |
	<a href="#getting-started">Getting Started</a> |
	<a href="#configuration">Configuration</a> |
	<a href="#usage">Usage</a> |
	<a href="#internationalization">Internationalization</a> |
	<a href="#faqs">FAQs</a> |
	<a href="#documentation">Documentation</a> |
	<a href="#contributing">Contributing</a> |
	<a href="#acknowledgements">Acknowledgements</a> 🥰
</h4>

<p align="center">
	<img src="images/CartUploadDemoComponent6.PNG" height=250>
</p>

---

## Features

- **bulk loading** Add up to 500 items to the cart from a CSV file or plain text
- **upload transcriptt** Receive a transcript of your upload via email
- **internationalized** Component is fully translatable into any language your store supports

## Getting Started

### Prerequisites

There are a few items you need to setup before installing:

1. You will need to [Enable Lightning Experience](https://trailhead.salesforce.com/en/content/learn/modules/lex_migration_introduction/lex_migration_introduction_administration).
2. You will need to [Enable My Domain](https://trailhead.salesforce.com/en/content/learn/modules/identity_login/identity_login_my_domain).

### Install

Deploy the source:

1. Clone this repository:

```
git clone git@github.com:sfdc-qbranch/B2BLECartUpload.git
cd B2BLECartUpload
```

2. Authorize with your org and provide it with an alias (OrgAlias):

```
sfdx force:auth:web:login -a "OrgAlias"
```

3. Push the app to your org:

```
sfdx force:source:deploy --sourcepath force-app/main/default --json --loglevel fatal --targetusername "OrgAlias"
```

4. Open the default org:

```
sfdx force:org:open --targetusername "OrgAlias"
```

## Configuration

### Security Updates

Make the following changes to your store user profile, or include in a permission set:

Enable the following System Permissions:
- Apex REST Services
- API Enabled

Enable access to these Apex Class Access:
- B2BAddToCartUtil
- B2BCartUploadHelp
- B2BProductEntitlementCheck
- CartUploadController

### Custom Settings

Under **Setup – Custom Code – Custom Settings**, click **Manage** for **B2B Cart Upload Settings**

<img src="images/CartUpload1.PNG" height="200">

Above Default Organization Level Value, click **[New]**

<img src="images/CartUpload2.PNG" height="200">

For the **REST API Domain** field, enter a value like this:  https://pkgtest2-20200825-1313-dev-ed.my.salesforce.com

<img src="images/CartUpload3.PNG" height="200">

NOTE: you can locate the appropriate domain under **Setup – User Interface – Domains**.  The one you want to use is “My Domain”.

Click **[Save]**.  Your screen should now look similar to the one below:

<img src="images/CartUpload4.PNG" height="150">

## Usage

### Add the component to your store
After installing the component, open your store’s community in Experience Builder.

Click the drop-down to the right of the Home page.

Click **[+ New Page]**

<img src="images/CartUpload5.PNG" height="400">

Click **[Standard Page]**

<img src="images/CartUpload6.PNG" height="300">

Click **[ + New Blank Page]**

<img src="images/CartUpload7.PNG" height="400">

Click **[Flexible Layout]**

<img src="images/CartUpload8.PNG" height="400">

Click **[Next]**

In the **New Page** dialog, enter “Cart Upload” for the **Name**.

You can leave API Name blank.

<img src="images/CartUpload9.PNG" height="300">

Click **[Create]**

In the new page, click on the **Components** button.  Scroll the list down until you see **Custom Components**

<img src="images/CartUpload10.PNG" height="400">

Drag the **B2B Cart Upload** component onto the page layout

<img src="images/CartUpload11.PNG" height="400">

Click **[Publish]** to save your changes.

### Create a Menu Item for your new page ###

Within **Experience Builder**, select the **Multi-level Navigation Menu** component.  The properties box will change to display those for that component

<img src="images/CartUpload14.PNG" height="400">

In the properties box, click **[Edit Default Navigation]**

Click **[+ Add Menu Item]**

<img src="images/CartUpload15.PNG" height="400">

A **New menu item** is added to the **Menu Structure**

<img src="images/CartUpload16.PNG" height="400">

Change the following values for the new menu item:

**Name**: Cart Upload
**Page**: select your new Cart Upload page

<img src="images/CartUpload17.PNG" height="400">

Click **[Save Menu]**
Click **[Publish]** to save your changes.

---

### 

### Supported Configuration Options

The component comes with several properties you can use to control how the component functions.

<img src="images/CartUpload12.PNG" height="400">

**Component Title:** the value in this property is displayed at the top of the component.  You can change this to a different title if you like

**Effective Account Id:** this property is used to pass the current community user’s effective account id to the component.  Changing this value is not recommended.

**Managed content Id:**  if you have created help documentation in Salesforce CMS, enter the content Id into this property to make it accessible within the component.

For example, if the URL to the content record is this:

https://pkgtest2-20200825-1313-dev-ed.lightning.force.com/lightning/cms/spaces/0Zu4W000000TPx5SAG/content/20Y4W000000L2DbUAK/5OU4W000000L4BBWA0

The Managed Content Id value you would enter into the component property would be:  20Y4W000000L2DbUAK

**Managed content type:**  enter “news”

**Email results checkbox enabled:**  Check this property to enable the Email results processing option by default within the component

**Show email results checkbox:**  Check this property to display the Email results checkbox in the component to store users.


Be sure to click [Publish] to save any property changes you make.


---

## Internationalization ##

### Custom Labels ###

The cart upload component fully supports internationalization.  You can translate all of the labels and messages displayed by the component into all languages your store and community support.  Just go into **Setup - User Interface - Custom Labels**, and translate the labels with the **b2bcu** namespace.

To make this task easier, you can create a **new view** of the custom labels that only include those from the **b2bcu** namespace:

<img src="images/CartUpload13.PNG" height="400">

### Translating your Menu Item ###

You can translate your new menu item within the **Translation Workbench**.
Go to **Setup – User Interface – Translation Workbench – Translate**.
In the **Select the filter criteria**, select

- **Language:** Select the language for the translation (i.e. Spanish)
- **Setup Component:** Navigation Menu Item
- **Expand** the navigation until you see your new menu item:

<img src="images/CartUpload18.PNG" height="400">

Hover over the **Navigation Menu Item Name Translation** cell until the **pencil icon** appears

<img src="images/CartUpload19.PNG" height="100">

**Double-click** on the pencil.
Enter your translation into the cell

<img src="images/CartUpload20.PNG" height="100">

Hit the **ENTER** key to record your translation

<img src="images/CartUpload21.PNG" height="100">

Click **[Save]** to save the translation

<img src="images/CartUpload23.PNG" height="200">

NOTE: it may take several hours for your translation to appear in the community.

---

## Documentation

Read [this document](docs/B2B+LE+Cart+Upload+Admin+Documentation.pdf) for external documentation on the component.

## FAQs

#### Does it work in Communities?

> Yes

#### Does it work in Mobile?

> Yes

#### Does it work with Person Accounts?

> No

#### Others?

## [Contributing](/CONTRIBUTING.md)

See the list of [Contributors][contributors-url] who participated in this project.

If you would like to join these awesome people, please refer to [contributing.md](/CONTRIBUTING.md) for guidelines.

## Acknowledgements

Special thanks to:

- Clay Phillips
- Anand Subbiah
- Steve Ecker
- Brooks Haines
- Jason Illg

## License

[![License][license-shield]][license-url] Copyright © 2021 [Salesforce][author-url]

<!--- Images -->

[license-shield]: https://img.shields.io/badge/License-BSD%203--Clause-blue.svg

<!--- Urls -->

[repository-url]: https://github.com/sfdc-qbranch/DemoComponentTemplate
[license-url]: http://opensource.org/licenses/BSD-3-Clause
[author-url]: http://github.com/paull10au
[contributors-url]: https://github.com/sfdc-qbranch/DemoComponentTemplate/contributors
[quip-url]: https://salesforce.quip.com/um8sAuXNyCnO
