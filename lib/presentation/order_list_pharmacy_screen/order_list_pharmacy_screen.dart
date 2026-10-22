import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_search_view.dart';
import 'widgets/list43218andyog_item_widget.dart';

// ignore_for_file: must_be_immutable
class OrderListPharmacyScreen extends StatelessWidget {
  OrderListPharmacyScreen({Key? key})
      : super(
          key: key,
        );

  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          height: SizeUtils.height,
          width: double.maxFinite,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: SizeUtils.height,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: double.maxFinite,
                      padding: EdgeInsets.only(top: 116.h),
                      decoration: AppDecoration.fillGray.copyWith(
                        borderRadius: BorderRadiusStyle.roundedBorder30,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.h),
                            child: CustomSearchView(
                              controller: searchController,
                              hintText: "Search",
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 18.h,
                                vertical: 14.h,
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          _buildSearchSection(context),
                          SizedBox(height: 256.h)
                        ],
                      ),
                    ),
                    _buildTopHeader(context)
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildSearchSection(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.maxFinite,
        decoration: AppDecoration.fFFFFFDropShadow.copyWith(
          borderRadius: BorderRadiusStyle.roundedBorder5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(height: 14.h),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                physics: BouncingScrollPhysics(),
                shrinkWrap: true,
                separatorBuilder: (context, index) {
                  return SizedBox(
                    height: 10.h,
                  );
                },
                itemCount: 3,
                itemBuilder: (context, index) {
                  return List43218andyogItemWidget();
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildTopHeader(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        margin: EdgeInsets.zero,
        color: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusStyle.customBorderTL30,
        ),
        child: Container(
          height: 100.h,
          padding: EdgeInsets.only(
            left: 18.h,
            right: 18.h,
            bottom: 20.h,
          ),
          decoration: AppDecoration.fillPrimary.copyWith(
            borderRadius: BorderRadiusStyle.customBorderTL30,
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CustomImageView(
                imagePath: ImageConstant.imgQdNotification,
                height: 30.h,
                width: 30.h,
                alignment: Alignment.bottomRight,
                margin: EdgeInsets.only(right: 32.h),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.maxFinite,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomImageView(
                          imagePath: ImageConstant.imgArrowDown,
                          height: 10.h,
                          width: 22.h,
                        ),
                        Spacer(
                          flex: 58,
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            "Order List",
                            style: CustomTextStyles.titleMediumWhiteA700Bold,
                          ),
                        ),
                        Spacer(
                          flex: 41,
                        ),
                        Container(
                          width: 14.h,
                          height: 12.h,
                          alignment: Alignment.center,
                          decoration: AppDecoration.fillRedA.copyWith(
                            borderRadius: BorderRadiusStyle.roundedBorder8,
                          ),
                          child: Text(
                            "8",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                        CustomImageView(
                          imagePath: ImageConstant.imgImage49,
                          height: 24.h,
                          width: 26.h,
                          radius: BorderRadius.circular(
                            12.h,
                          ),
                          alignment: Alignment.bottomCenter,
                          margin: EdgeInsets.only(
                            left: 4.h,
                            top: 12.h,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
