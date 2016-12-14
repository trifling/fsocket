# This file is part of closest, a library for cull-based and 
# cell-based spatial search of k-nearest neighbors in n-dimensions.
# Copyright (C) 2011-2016 Daniel Pena <trifling.github@gmail.com>
#
# Closest is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Closest is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with closest. If not, see <http://www.gnu.org/licenses/>.
 
INCLUDE(FindPythonModule)

FIND_PYTHON_MODULE(sphinxfortran)

IF( ${sphinxfortran_FOUND} )
   INCLUDE(FindPythonSphinx)
ENDIF()

