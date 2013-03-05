# SOLI #
Soli is a small interpreter of a simple object-oriented language named sol.
You can find examples of the language syntax in the data/test.txt file.

## Installation ##

### Linux ###

1. Download sources

2. Install dependances:

  Debian, Ubuntu...:
  ```
  sudo apt-get install libgee-dev libglib2.0-dev libgtk-3-dev libgtksourceview-3.0-dev valac cmake
  ```

  Fedora:
  ```
  sudo yum install libgee-devel glib2-devel gtk3-devel gtksourceview3-devel vala cmake
  ```

3. Open a terminal in the root folder

4. Build it by running:
  ```
  cmake .
  ```
  ```
  make
  ```

5. Run the GUI with:
  ```
  ./soli
  ```
