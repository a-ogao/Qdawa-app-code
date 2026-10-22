import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0XFF4675C0),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Privacy Policy",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0XFF4675C0).withValues(alpha: 0.05),
              Colors.grey[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Privacy Policy for QuikDawa",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Effective Date: Oct 2024",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildSectionTitle("1. Introduction"),
                      _buildSectionContent(
                          "This Privacy Policy ('Policy') applies to the collection of Personal Information by QuikDawa. and our affiliated companies and subsidiaries (referred to herein as 'QuikDawa,' 'us,' or 'we'). This Privacy Policy applies to QuikDawa products, communications, digital properties including websites, online platforms, and mobile applications, that refer to this Privacy Policy, any offline interactions that we may have with you, and where Humana may obtain and control your Personal Information (as defined herein) from a third party (collectively, the 'Solution'). This Privacy Policy describes how QuikDawa collects and uses the Personal Information. It also describes the choices available to you regarding our use of your Personal Information and how you can access and update this information. "
                          "We respect your concerns about privacy. We value your privacy and are committed to protecting your personal data. This Policy describes the personal information we may obtain about you, when you use the Solution, our Text Messaging Program, and other related online and offline services and communications with us (collectively, the 'Solution'). We also describe how we may use and disclose that information, and explain the choices available to you regarding our use of the information, the measures we take to protect the security of the information, and how you can contact us if you have any questions about our privacy practices. "
                          "This Policy and your use of any of our Solution is subject to our Terms & Conditions ('Terms'), and by registering for or otherwise using our Solution, you agree to be bound by our Terms and this Policy. If you have questions about this Policy, please contact us as directed below. "),
                      _buildSectionTitle("2. Data Collection"),
                      _buildSectionContent(
                          "We collect personal data that you provide directly to us and automatically through your use of the Solution, some examples \n"
                          "- Contact information including your name, mailing address, email address, and telephone number;\n "
                          "- Your information associated with a QuikDawa account, including login credentials (e.g., username and password), profile information and subscription preferences;\n "
                          "- Demographic information such as date of birth and gender;\n "
                          "- Transaction information such as purchase history, returns, or exchanges;\n "
                          "- Use of certain services such as if you arrange to pick up your retail order, or have your order delivered to your home;\n "
                          "- Information about the apps, browsers and devices you use to access our Online Services including your computer's IP address and/or mobile device information (e.g., device model, operating system version, unique device identifiers, mobile network information);\n "
                          "- Geolocation data associated with your use of the Solution;\n "
                          "- Images you provide to us (e.g., when you upload photos);\n "
                          "- Individuals who provide services that within the Solution;\n "
                          "- We collect information from you when you provide us with feedback and we may collect information regarding your receipt and interaction with emails and other messages that you receive from us;\n "),
                      _buildSectionTitle("3. Use of Data"),
                      _buildSectionContent("We use your personal data to: \n"
                          "- Provide our products and services, such as to create and manage QuikDawa accounts and loyalty programs, facilitate purchases, process and fulfill orders, keep you informed about the status of your orders (including messaging with providers, who may provide you with health care information), and provide related customer and technical support;\n"
                          "- Personalize your experience while using our Solution, and communicate with you about products and services that may be of interest to you, including promotional materials about QuikDawa and third-party products and services;\n"
                          "- Provide and administer your participation in surveys, events, contests and programs (including discount or coupon-related offers); \n"
                          "- Provide you with location-based information; \n"
                          "- Operate, evaluate, develop, manage and improve our business (including operating, administering, analyzing, and improving our Solution; developing new products and services; managing and evaluating the effectiveness of our communications; conducting market research, aggregating and anonymizing data, and performing data analytics; facilitating the provision of services to QuikDawa; and performing accounting, auditing, and other internal functions); \n"
                          "- Protect against, identify, and respond to suspected fraud, criminal activity, violations of law or our Terms and other policies, or any harm to our staff or any other individual;  \n"
                          "- Comply with and enforce applicable legal requirements, relevant industry standards, contractual obligations, and our policies, including this Privacy Policy, and our Terms and Conditions \n"),
                      _buildSectionTitle("4. Sources of Personal Information"),
                      _buildSectionContent(
                          "We collect the personal information described above from the following sources. \n"
                          "- Directly from you. We collect personal information directly from you when you interact with us through our services and automatically when you visit our websites and mobile applications.\n"
                          "- From subsidiaries and affiliates. We collect personal information from our subsidiaries and affiliates you interact with as permitted by applicable law.\n"
                          "- Publicly available information and other sources. We may collect information about you from both publicly available and other third-party sources to enhance and improve the accuracy of our information about you. We may combine the information we collect from you through the Commercial Services with information we get from and about you from other online and offline sources. We may use the combined information in accordance with this Privacy Policy. \n"),
                      _buildSectionTitle("5. Data Sharing"),
                      _buildSectionContent(
                          "We may share information about you with the following categories of third-parties, where consistent with this Policy and applicable laws: /n "
                          "- We may share your information as instructed by you, such as with healthcare providers, benefit managers, discount card providers and others at your express direction; /n"
                          "- We engage in some forms of third-party advertising activities which you can opt-out of; /n"
                          "- Our legal affiliates and agents in connection with our business operations /n"
                          "- Our service providers (e.g., IT services, maintenance and hosting of our Solution, payment processors, marketing and analytics, customer communications, order fulfillment and shipping), but we only provide information to these providers to perform their required functions on our behalf; and /n"
                          "- Third-party brand manufacturers with whom we may partner to develop discount or coupon programs for retail products, and likewise with third-parties who provide services that we offer through our Solution. /n"
                          "We also may disclose information about you in certain unusual circumstances, including (1) if we are required to do so by law or legal process; (2) in response to requests by government agencies, such as law enforcement authorities; (3) to establish, exercise, or defend our legal rights; (4) when we believe disclosure is necessary or appropriate to prevent physical or other harm or financial loss; (5) in connection with an investigation of suspected or actual fraud or other illegal activity; or (6) in the event we sell or transfer (or contemplate the sale or transfer of) all or a relevant portion of our business or assets (including in the event of a merger, acquisition, joint venture, reorganization, divestiture, dissolution, or liquidation). "),
                      _buildSectionTitle("6. Data Security"),
                      _buildSectionContent(
                          "We maintain administrative, technical, and physical safeguards designed to protect personal information against accidental, unlawful, or unauthorized destruction, loss, alteration, access, disclosure, or use. No data transmission or storage is 100% secure, and we cannot guarantee that information you send to us online or via email, or information that we maintain about you, will not be accessed, disclosed, altered, or destroyed. We will make any legally required disclosures of any breach of the security, confidentiality, or integrity of your personal information. To the extent the law of your jurisdiction allows for notification of a security or privacy incident via e-mail or the Services, you agree to accept notice in that form.\n"
                          "We retain personal information based on several factors, including (i) for business purposes, such as the duration your account remains active, the period reasonably necessary to deliver our products and services, and other purposes outlined above for which we use your information, and (ii) as reasonably necessary to comply with our legal obligations, resolve disputes and enforce our agreements. We may also retain cached or archived copies of your information for a reasonable period of time. \n"),
                      _buildSectionTitle("7. Your Rights"),
                      _buildSectionContent("You have the right to:\n"
                          "You have the right to access, correct, or delete your personal data. You can also object to or restrict certain processing of your data.\n"),
                      _buildSectionTitle("8. Changes to This Policy"),
                      _buildSectionContent(
                          "We may update this Policy from time to time and without prior notice to you, such as to reflect changes in our personal information practices with respect to our Solution, or to comply with new privacy laws or best practices. We will indicate at the top of the Policy when it was most recently updated. By continuing to use any Solution after such a change, you agree to the updated Policy."),
                      _buildSectionTitle("9. Contact Us"),
                      _buildSectionContent(
                          "If you have any questions or concerns about this policy, please contact us at support@quikdawa.com."),
                    ],
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Text(
        content,
        style: TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }
}
