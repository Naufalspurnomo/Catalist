import React, { useState, useMemo } from "react";
import {
  useTable,
  useSortBy,
  useGlobalFilter,
  usePagination,
} from "react-table";
import {
  FiChevronDown,
  FiChevronUp,
  FiSearch,
  FiChevronLeft,
  FiChevronRight,
  FiUser,
  FiToggleLeft,
  FiToggleRight,
} from "react-icons/fi";

const UsersTable = ({ users, loading, onToggleStatus }) => {
  const [filterInput, setFilterInput] = useState("");

  // Format date
  const formatDate = (dateString) => {
    const options = {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    };
    return new Date(dateString).toLocaleDateString("id-ID", options);
  };

  // Define columns
  const columns = useMemo(
    () => [
      {
        Header: "Pengguna",
        accessor: "email",
        Cell: ({ row }) => (
          <div className="flex items-center">
            <div className="h-10 w-10 flex-shrink-0 bg-gray-200 rounded-full flex items-center justify-center">
              {row.original.avatar_url ? (
                <img
                  className="h-10 w-10 rounded-full object-cover"
                  src={row.original.avatar_url}
                  alt={row.original.email}
                />
              ) : (
                <FiUser className="text-gray-500" />
              )}
            </div>
            <div className="ml-4">
              <div className="text-sm font-medium text-gray-900">
                {row.original.full_name || "Unnamed User"}
              </div>
              <div className="text-sm text-gray-500">{row.original.email}</div>
            </div>
          </div>
        ),
      },
      {
        Header: "Role",
        accessor: "role",
        Cell: ({ value }) => (
          <span
            className={`px-2 py-1 text-xs rounded-full ${
              value === "admin"
                ? "bg-purple-100 text-purple-800"
                : "bg-blue-100 text-blue-800"
            }`}
          >
            {value || "customer"}
          </span>
        ),
      },
      {
        Header: "Status",
        accessor: "is_active",
        Cell: ({ value, row }) => (
          <span
            className={`px-2 py-1 text-xs rounded-full ${
              value ? "bg-green-100 text-green-800" : "bg-red-100 text-red-800"
            }`}
          >
            {value ? "Aktif" : "Nonaktif"}
          </span>
        ),
      },
      {
        Header: "Tanggal Daftar",
        accessor: "created_at",
        Cell: ({ value }) => formatDate(value),
      },
      {
        Header: "Aksi",
        accessor: "id",
        Cell: ({ value, row }) => (
          <button
            onClick={() => onToggleStatus(value, !row.original.is_active)}
            className={`text-${
              row.original.is_active ? "red" : "green"
            }-500 hover:text-${row.original.is_active ? "red" : "green"}-700`}
            title={row.original.is_active ? "Nonaktifkan" : "Aktifkan"}
          >
            {row.original.is_active ? (
              <FiToggleRight className="h-6 w-6" />
            ) : (
              <FiToggleLeft className="h-6 w-6" />
            )}
          </button>
        ),
        disableSortBy: true,
      },
    ],
    [onToggleStatus]
  );

  // Use the useTable hook to create the table configuration
  const {
    getTableProps,
    getTableBodyProps,
    headerGroups,
    page,
    prepareRow,
    state,
    setGlobalFilter,
    canPreviousPage,
    canNextPage,
    pageOptions,
    pageCount,
    gotoPage,
    nextPage,
    previousPage,
    setPageSize,
  } = useTable(
    {
      columns,
      data: users,
      initialState: { pageIndex: 0, pageSize: 10 },
    },
    useGlobalFilter,
    useSortBy,
    usePagination
  );

  // Update the global filter when the filter input changes
  const handleFilterChange = (e) => {
    const value = e.target.value || "";
    setGlobalFilter(value);
    setFilterInput(value);
  };

  // Loading state
  if (loading) {
    return (
      <div className="bg-white rounded-xl shadow-md overflow-hidden">
        <div className="p-6 border-b border-gray-200 flex justify-between items-center">
          <h3 className="text-lg font-medium text-gray-900">Daftar Pengguna</h3>
          <div className="animate-pulse w-64 h-10 bg-gray-200 rounded"></div>
        </div>
        <div className="animate-pulse">
          <div className="h-12 bg-gray-100 border-b border-gray-200"></div>
          {[...Array(5)].map((_, index) => (
            <div key={index} className="h-16 border-b border-gray-200"></div>
          ))}
        </div>
        <div className="p-4 border-t border-gray-200">
          <div className="animate-pulse w-full h-10 bg-gray-200 rounded"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-xl shadow-md overflow-hidden">
      <div className="p-6 border-b border-gray-200 flex flex-col md:flex-row justify-between items-start md:items-center space-y-4 md:space-y-0">
        <h3 className="text-lg font-medium text-gray-900">Daftar Pengguna</h3>
        <div className="flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-2 w-full md:w-auto">
          <div className="relative">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <FiSearch className="text-gray-400" />
            </div>
            <input
              value={filterInput}
              onChange={handleFilterChange}
              placeholder="Cari pengguna..."
              className="form-input pl-10 py-2 w-full sm:w-64"
            />
          </div>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table
          {...getTableProps()}
          className="min-w-full divide-y divide-gray-200"
        >
          <thead className="bg-gray-50">
            {headerGroups.map((headerGroup) => {
              // REVISI DI SINI: Pisahkan 'key' dari props <tr>
              const { key: headerGroupKey, ...otherHeaderGroupProps } =
                headerGroup.getHeaderGroupProps();

              return (
                <tr key={headerGroupKey} {...otherHeaderGroupProps}>
                  {headerGroup.headers.map((column) => {
                    // REVISI DI SINI: Pisahkan 'key' dari props <th>
                    const thProps = column.getHeaderProps(
                      column.getSortByToggleProps()
                    );
                    const { key: thKey, ...otherThProps } = thProps;

                    return (
                      <th
                        key={thKey}
                        {...otherThProps}
                        className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        <div className="flex items-center">
                          {column.render("Header")}
                          <span>
                            {column.isSorted ? (
                              column.isSortedDesc ? (
                                <FiChevronDown className="ml-1" />
                              ) : (
                                <FiChevronUp className="ml-1" />
                              )
                            ) : (
                              ""
                            )}
                          </span>
                        </div>
                      </th>
                    );
                  })}
                </tr>
              );
            })}
          </thead>
          <tbody
            {...getTableBodyProps()}
            className="bg-white divide-y divide-gray-200"
          >
            {page.length === 0 ? (
              <tr>
                <td
                  colSpan={columns.length}
                  className="px-6 py-4 text-center text-gray-500"
                >
                  Tidak ada pengguna yang ditemukan
                </td>
              </tr>
            ) : (
              page.map((row) => {
                prepareRow(row);

                // REVISI DI SINI: Pisahkan 'key' dari props <tr> (baris 226)
                const { key: rowKey, ...otherRowProps } = row.getRowProps();

                return (
                  <tr
                    key={rowKey}
                    {...otherRowProps}
                    className="hover:bg-gray-50"
                  >
                    {row.cells.map((cell) => {
                      // REVISI DI SINI: Pisahkan 'key' dari props <td> (baris 227)
                      const { key: cellKey, ...otherCellProps } =
                        cell.getCellProps();

                      return (
                        <td
                          key={cellKey}
                          {...otherCellProps}
                          className="px-6 py-4 whitespace-nowrap text-sm text-gray-500"
                        >
                          {cell.render("Cell")}
                        </td>
                      );
                    })}
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      <div className="px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
        <div className="flex-1 flex justify-between sm:hidden">
          <button
            onClick={() => previousPage()}
            disabled={!canPreviousPage}
            className="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Previous
          </button>
          <button
            onClick={() => nextPage()}
            disabled={!canNextPage}
            className="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Next
          </button>
        </div>
        <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
          <div>
            <p className="text-sm text-gray-700">
              Menampilkan{" "}
              <span className="font-medium">
                {page.length === 0 ? 0 : state.pageIndex * state.pageSize + 1}
              </span>{" "}
              -{" "}
              <span className="font-medium">
                {Math.min((state.pageIndex + 1) * state.pageSize, users.length)}
              </span>{" "}
              dari <span className="font-medium">{users.length}</span> hasil
            </p>
          </div>
          <div>
            <nav
              className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
              aria-label="Pagination"
            >
              <button
                onClick={() => gotoPage(0)}
                disabled={!canPreviousPage}
                className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <span className="sr-only">First</span>
                <FiChevronLeft className="h-5 w-5" />
                <FiChevronLeft className="h-5 w-5 -ml-2" />
              </button>
              <button
                onClick={() => previousPage()}
                disabled={!canPreviousPage}
                className="relative inline-flex items-center px-2 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <span className="sr-only">Previous</span>
                <FiChevronLeft className="h-5 w-5" />
              </button>

              {/* Page numbers */}
              {[...Array(pageCount)].map((_, index) => (
                <button
                  key={index}
                  onClick={() => gotoPage(index)}
                  className={`relative inline-flex items-center px-4 py-2 border text-sm font-medium ${
                    state.pageIndex === index
                      ? "z-10 bg-primary border-primary text-dark"
                      : "bg-white border-gray-300 text-gray-500 hover:bg-gray-50"
                  }`}
                >
                  {index + 1}
                </button>
              ))}

              <button
                onClick={() => nextPage()}
                disabled={!canNextPage}
                className="relative inline-flex items-center px-2 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <span className="sr-only">Next</span>
                <FiChevronRight className="h-5 w-5" />
              </button>
              <button
                onClick={() => gotoPage(pageCount - 1)}
                disabled={!canNextPage}
                className="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <span className="sr-only">Last</span>
                <FiChevronRight className="h-5 w-5" />
                <FiChevronRight className="h-5 w-5 -ml-2" />
              </button>
            </nav>
          </div>
        </div>
      </div>
    </div>
  );
};

export default UsersTable;
