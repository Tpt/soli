cmake_minimum_required(VERSION 2.6)
cmake_policy(VERSION 2.6)
cmake_policy(SET CMP0015 OLD)

set(PROJECT_NAME "SOLI")
set(PROJECT_VERSION "0.1")


message (STATUS "*** Building ${PROJECT_NAME} ${PROJECT_VERSION} ***")

project(Soli C)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

include(FindVala)
find_package(Vala REQUIRED)

include(UseVala)

vala_precompile(
VALA_C
	src/main.vala
	src/main-ui.vala
	src/string-utils.vala
	src/config.vala
	src/test.vala

	src/parser/tokenizer.vala
	src/parser/parser.vala

	src/language/element.vala
	src/language/struct.vala
	src/language/operator.vala
	src/language/var.vala
	src/language/memory.vala
	src/language/function.vala
	src/language/class.vala
	src/language/custom-class.vala
	src/language/binding-class.vala
	src/language/object.vala
	src/language/class-provider.vala
	src/language/null-class.vala

	src/library/boolean.vala
	src/library/integer.vala
	src/library/float.vala
	src/library/string.vala
	src/library/collection.vala
	src/library/map.vala
PACKAGES
	gee-0.8
	gtk+-3.0
	gtksourceview-3.0
OPTIONS
CUSTOM_VAPIS
)

find_package(PkgConfig)
pkg_check_modules(GLIB REQUIRED glib-2.0)
pkg_check_modules(GOBJECT REQUIRED gobject-2.0)
pkg_check_modules(GTK REQUIRED gtk+-3.0)
pkg_check_modules(GTKSOURCEVIEW REQUIRED gtksourceview-3.0)
pkg_check_modules(GEE REQUIRED gee-0.8)
if ( NOT GEE_FOUND )
	pkg_check_modules(GEE REQUIRED gee-1.0)
endif ( NOT GEE_FOUND )

add_definitions(${GLIB_CFLAGS} ${GOBJECT_CFLAGS} ${GEE_CFLAGS} ${GTK_CFLAGS} ${GTKSOURCEVIEW_CFLAGS})
link_libraries(${GLIB_LIBRARIES} ${GOBJECT_LIBRARIES} ${GEE_LIBRARIES} ${GTK_LIBRARIES} ${GTKSOURCEVIEW_LIBRARIES})
link_directories(${GLIB_LIBRARY_DIRS} ${GEE_LIBRARY_DIRS}  ${GTK_LIBRARIES}  ${GTKSOURCEVIEW_LIBRARIES})

file(COPY ${CMAKE_SOURCE_DIR}/data/ DESTINATION ${CMAKE_BINARY_DIR}/)

add_executable(soli ${VALA_C})
