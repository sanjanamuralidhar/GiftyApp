import 'package:giftty/Model/Section_Model.dart';


class ApiResultModel {
  String status;
  int totalResults;
  List<Product> articles;

  ApiResultModel({this.status, this.totalResults, this.articles});

  ApiResultModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    totalResults = json['totalResults'];
    if (json['articles'] != null) {
      articles = new List<Product>();
      json['articles'].forEach((v) {
        articles.add(new Product.fromJson(v));
      });
    }
  }

  // Map<String, dynamic> toJson() {
  //   final Map<String, dynamic> data = new Map<String, dynamic>();
  //   data['status'] = this.status;
  //   data['totalResults'] = this.totalResults;
  //   if (this.articles != null) {
  //     data['articles'] = this.articles.map((v) => v.toJson()).toList();
  //   }
  //   return data;
  // }
}

class Articles {
  Source source;
  Null author;
  String title;
  String description;
  String url;
  String urlToImage;
  String publishedAt;
  String content;

  Articles(
      {this.source,
      this.author,
      this.title,
      this.description,
      this.url,
      this.urlToImage,
      this.publishedAt,
      this.content});

  Articles.fromJson(Map<String, dynamic> json) {
    source =
        json['source'] != null ? new Source.fromJson(json['source']) : null;
    author = json['author'];
    title = json['title'];
    description = json['description'];
    url = json['url'];
    urlToImage = json['urlToImage'];
    publishedAt = json['publishedAt'];
    content = json['content'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.source != null) {
      data['source'] = this.source.toJson();
    }
    data['author'] = this.author;
    data['title'] = this.title;
    data['description'] = this.description;
    data['url'] = this.url;
    data['urlToImage'] = this.urlToImage;
    data['publishedAt'] = this.publishedAt;
    data['content'] = this.content;
    return data;
  }
}

class Source {
  String id;
  String name;

  Source({this.id, this.name});

  Source.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    return data;
  }
}

// import 'Section_Model.dart';

// class CategoryPageModel {
//   String success;
//   String message;
//   List<Product> category;

//   CategoryPageModel(
//     this.category,
//   );
//    @override
//   String toString() {
//     return toJson().toString();
//   }

//   CategoryPageModel.fromJson(Map<String, dynamic> json) {
//     if (json == null) return;
//     success = json['success'];
//     message = json['message'];
//    category=_setList(json['data']);  
//   }

//   Map<String, dynamic> toJson() {
//     Map<String, dynamic> json = {};
//     if(success!=null) json['success']=success;
//     if(message!=null) json['message']=message;
//     if (category != null) json['data'] = category;
//      return json;
//   }

//     static List<Product> _setList(list) {
//     if (list != null) {
//       final Iterable refactorFeature = list;
//       return refactorFeature.map((item) {
//         return Product.fromJson(item);
//       }).toList();
//     }
//     return null;
//   }

//   static List<CategoryPageModel> listFromJson(List<dynamic> json) {
//     return json == null
//         ? List<CategoryPageModel>()
//         : json.map((value) => CategoryPageModel.fromJson(value)).toList();
//   }
 
// }