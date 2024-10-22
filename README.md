# Pelican - another Flutter Router

The Pelican is a large migratory bird https://en.wikipedia.org/wiki/Australian_pelican

## Why another Flutter router ?

I have spent a lot of time with routing in other app development environments, like Rails, Ember and Xamarin and researched Flutter packages and the Navigator 2.0 API.
None of the available options met my core requirements, being :

* async everything
* an expressive route table (of segments)
* no code generation
* parameters and options per segment. Parameters affect routing, options do not.
* two-way serialization between the page stack and the route (like Rails and Ember.js)
* defined segments, dynamically constructed route (of segments)
* no heirarchy in the definition of segments means segments/pages can be dynamically constructed in any order within a route/stack
* full-route redirects
* segment redirects ("aliases") - future feature
* ability to goto any route, and intelligently create or destroy pages as required
* a stack of pages, not a history of routes. Back = pop(), or you can goto any route you've stored.
* uses Navigator 2.0 as it was intended

If you've written a popular Flutter routing package, go ahead and steal my ideas. I don't really want to be a package maintainer.

I make no claim of the completeness or quality of this repository, but I use it in production, and develop it as required by the application.
This is not the latest version, but I intend to update it from my production app.
Some intended features are not properly implemented yet.

Acknowledgements
* https://pub.dev/packages/beamer
* https://pub.dev/packages/routemaster


## Documentation

### Segment Paths

* A segment path looks like

```<page>[;(param[=value])*][+](option[=value])*```

Examples

```Book;id=1+color=red```

```Books```

```Books+search=hardy```

* A route is zero or more segments, joined by /

For example :

```/Home/Books+search=hardy```

"search" is an option that allows values to be passed without affecting routing

```/Home/Books+search=hardy/Settings```

```/Home/Books+search=hardy/Book;id=1```

"id" is a parameter that can affect routing

```/Home/Books+search=hardy/Book;id=1/Settings```

The "Settings" page can be shown anywhere on the stack, and even multiple times - we don't need to define routes for all possible stack routes

### RouteTable

This specifies :
* a builder for each segment. The segment definition string optionally defines parameters and options and their order. The builder uses the passed context object (_) for context information and performing actions
* a handler for each redirect. The entire route path is matched against the provided redirect paths, and then a handler returns the new path string.

```
PelicanRouter router = PelicanRouter(
  '/books',
  RouteTable(
    {
      'books': (_) async {
        return _.page(
          BooksListScreen(
            books: books,
            onTapped: (book) {
              router.state.push("book;id=${book.id}");
            }
          )
        );
      },
      'book;id+color;size': (_) async {
        var book = books.firstWhere((b) => b.id==_.segment!.params['id']);
        return _.page(BookDetailsScreen(book: book));
      }
    },
    redirects: {
      '/': (_) async => '/books'
    }
  ),
);
```

### Navigation

Examples :

```router.state.push("book;id=${book.id}")```

```router.state.pop()```

```router.state.goto('/login')```


