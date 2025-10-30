import React, { useState, useEffect } from "react";
import supabase from "../lib/supabase";
import UsersTable from "../components/UsersTable";
import {
  FiRefreshCw,
  FiAlertTriangle,
  FiCheck,
  FiUserPlus,
  FiUsers,
} from "react-icons/fi";

const Users = () => {
  // State
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [roleFilter, setRoleFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [stats, setStats] = useState({
    total: 0,
    admin: 0,
    customer: 0,
    active: 0,
    inactive: 0,
  });
  const [showAddModal, setShowAddModal] = useState(false);
  const [newUser, setNewUser] = useState({
    email: "",
    password: "",
    role: "customer",
  });
  const [addLoading, setAddLoading] = useState(false);
  const [addError, setAddError] = useState(null);

  // Fetch users
  useEffect(() => {
    fetchUsers();
  }, [roleFilter, statusFilter]);

  // Fetch users from Supabase
  const fetchUsers = async () => {
    try {
      setLoading(true);
      setError(null);

      // Build query
      let query = supabase
        .from("profiles")
        .select(
          `
  id,
  email,
  display_name,
  avatar_url,
  phone,
  bio,
  location,
  role,
  created_at
`
        )

        .order("created_at", { ascending: false });

      // Apply role filter
      if (roleFilter !== "all") {
        query = query.eq("role", roleFilter);
      }

      // Apply status filter
      if (statusFilter !== "all") {
        const isActive = statusFilter === "active";
        query = query.eq("is_active", isActive);
      }

      // Execute query
      const { data, error } = await query;

      if (error) throw error;

      setUsers(data || []);

      // Calculate stats
      await fetchUserStats();
    } catch (error) {
      console.error("Error fetching users:", error);
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  // Fetch user stats
  const fetchUserStats = async () => {
    try {
      // Get total count
      const { count: total, error: totalError } = await supabase
        .from("profiles")
        .select("id", { count: "exact" });

      if (totalError) throw totalError;

      // Get admin count
      const { count: adminCount, error: adminError } = await supabase
        .from("profiles")
        .select("id", { count: "exact" })
        .eq("role", "admin");

      if (adminError) throw adminError;

      // Get customer count
      const { count: customerCount, error: customerError } = await supabase
        .from("profiles")
        .select("id", { count: "exact" })
        .eq("role", "customer");

      if (customerError) throw customerError;

      // Get active count
      const { count: activeCount, error: activeError } = await supabase
        .from("profiles")
        .select("id", { count: "exact" })
        .eq("is_active", true);

      if (activeError) throw activeError;

      // Get inactive count
      const { count: inactiveCount, error: inactiveError } = await supabase
        .from("profiles")
        .select("id", { count: "exact" })
        .eq("is_active", false);

      if (inactiveError) throw inactiveError;

      setStats({
        total,
        admin: adminCount,
        customer: customerCount,
        active: activeCount,
        inactive: inactiveCount,
      });
    } catch (error) {
      console.error("Error fetching user stats:", error);
    }
  };

  // Handle role filter change
  const handleRoleChange = (role) => {
    setRoleFilter(role);
  };

  // Handle status filter change
  const handleStatusChange = (status) => {
    setStatusFilter(status);
  };

  // Handle refresh
  const handleRefresh = () => {
    fetchUsers();
  };

  // Handle toggle user status
  const handleToggleStatus = async (userId, newStatus) => {
    try {
      setLoading(true);
      setError(null);
      setSuccess(null);

      // Update user status
      const { error } = await supabase
        .from("profiles")
        .update({
          is_active: newStatus,
          updated_at: new Date().toISOString(),
        })
        .eq("id", userId);

      if (error) throw error;

      // Refresh users
      await fetchUsers();

      setSuccess(
        `Pengguna berhasil ${newStatus ? "diaktifkan" : "dinonaktifkan"}`
      );

      // Hide success message after 3 seconds
      setTimeout(() => {
        setSuccess(null);
      }, 3000);
    } catch (error) {
      console.error("Error toggling user status:", error);
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  // Handle add user
  const handleAddUser = async (e) => {
    e.preventDefault();

    try {
      setAddLoading(true);
      setAddError(null);

      // Validate form
      if (!newUser.email || !newUser.password) {
        throw new Error("Email dan password harus diisi");
      }

      // Create user with Supabase Auth
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: newUser.email,
        password: newUser.password,
      });

      if (authError) throw authError;

      // Create profile
      const { error: profileError } = await supabase.from("profiles").upsert({
        id: authData.user.id,
        email: newUser.email,
        role: newUser.role,
        is_active: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });

      if (profileError) throw profileError;

      // Close modal and reset form
      setShowAddModal(false);
      setNewUser({
        email: "",
        password: "",
        role: "customer",
      });

      // Refresh users
      await fetchUsers();

      setSuccess("Pengguna berhasil ditambahkan");

      // Hide success message after 3 seconds
      setTimeout(() => {
        setSuccess(null);
      }, 3000);
    } catch (error) {
      console.error("Error adding user:", error);
      setAddError(error.message);
    } finally {
      setAddLoading(false);
    }
  };

  // Handle input change
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setNewUser((prev) => ({ ...prev, [name]: value }));
  };

  return (
    <div>
      <div className="mb-6 flex flex-col sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">
            Manajemen Pengguna
          </h1>
          <p className="text-gray-500">Kelola dan pantau semua pengguna</p>
        </div>
        <div className="mt-4 sm:mt-0 flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-2">
          <button
            onClick={handleRefresh}
            className="btn btn-outline flex items-center"
            disabled={loading}
          >
            <FiRefreshCw className={`mr-2 ${loading ? "animate-spin" : ""}`} />
            Refresh
          </button>
          <button
            onClick={() => setShowAddModal(true)}
            className="btn btn-primary flex items-center"
          >
            <FiUserPlus className="mr-2" />
            Tambah Pengguna
          </button>
        </div>
      </div>

      {/* Error message */}
      {error && (
        <div className="bg-red-50 border-l-4 border-red-500 p-4 mb-6">
          <div className="flex items-center">
            <FiAlertTriangle className="text-red-500 mr-3" />
            <p className="text-sm text-red-700">{error}</p>
          </div>
        </div>
      )}

      {/* Success message */}
      {success && (
        <div className="bg-green-50 border-l-4 border-green-500 p-4 mb-6">
          <div className="flex items-center">
            <FiCheck className="text-green-500 mr-3" />
            <p className="text-sm text-green-700">{success}</p>
          </div>
        </div>
      )}

      {/* User Stats */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-6">
        <div
          className={`bg-white rounded-lg shadow-sm p-4 cursor-pointer border-2 ${
            roleFilter === "all" && statusFilter === "all"
              ? "border-primary"
              : "border-transparent"
          }`}
          onClick={() => {
            handleRoleChange("all");
            handleStatusChange("all");
          }}
        >
          <div className="flex items-center">
            <FiUsers className="text-gray-500 mr-2" />
            <p className="text-sm text-gray-500">Semua</p>
          </div>
          <p className="text-xl font-bold">{stats.total}</p>
        </div>
        <div
          className={`bg-white rounded-lg shadow-sm p-4 cursor-pointer border-2 ${
            roleFilter === "admin" ? "border-primary" : "border-transparent"
          }`}
          onClick={() => handleRoleChange("admin")}
        >
          <div className="flex items-center">
            <FiUsers className="text-purple-500 mr-2" />
            <p className="text-sm text-gray-500">Admin</p>
          </div>
          <p className="text-xl font-bold">{stats.admin}</p>
        </div>
        <div
          className={`bg-white rounded-lg shadow-sm p-4 cursor-pointer border-2 ${
            roleFilter === "customer" ? "border-primary" : "border-transparent"
          }`}
          onClick={() => handleRoleChange("customer")}
        >
          <div className="flex items-center">
            <FiUsers className="text-blue-500 mr-2" />
            <p className="text-sm text-gray-500">Customer</p>
          </div>
          <p className="text-xl font-bold">{stats.customer}</p>
        </div>
        <div
          className={`bg-white rounded-lg shadow-sm p-4 cursor-pointer border-2 ${
            statusFilter === "active" ? "border-primary" : "border-transparent"
          }`}
          onClick={() => handleStatusChange("active")}
        >
          <div className="flex items-center">
            <FiUsers className="text-green-500 mr-2" />
            <p className="text-sm text-gray-500">Aktif</p>
          </div>
          <p className="text-xl font-bold">{stats.active}</p>
        </div>
        <div
          className={`bg-white rounded-lg shadow-sm p-4 cursor-pointer border-2 ${
            statusFilter === "inactive"
              ? "border-primary"
              : "border-transparent"
          }`}
          onClick={() => handleStatusChange("inactive")}
        >
          <div className="flex items-center">
            <FiUsers className="text-red-500 mr-2" />
            <p className="text-sm text-gray-500">Nonaktif</p>
          </div>
          <p className="text-xl font-bold">{stats.inactive}</p>
        </div>
      </div>

      {/* Users Table */}
      <UsersTable
        users={users}
        loading={loading}
        onToggleStatus={handleToggleStatus}
      />

      {/* Add User Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div
              className="fixed inset-0 transition-opacity"
              aria-hidden="true"
            >
              <div className="absolute inset-0 bg-gray-500 opacity-75"></div>
            </div>

            <span
              className="hidden sm:inline-block sm:align-middle sm:h-screen"
              aria-hidden="true"
            >
              &#8203;
            </span>

            <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
              <form onSubmit={handleAddUser}>
                <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                  <div className="sm:flex sm:items-start">
                    <div className="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-blue-100 sm:mx-0 sm:h-10 sm:w-10">
                      <FiUserPlus className="h-6 w-6 text-blue-600" />
                    </div>
                    <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full">
                      <h3 className="text-lg leading-6 font-medium text-gray-900">
                        Tambah Pengguna Baru
                      </h3>

                      {/* Error message */}
                      {addError && (
                        <div className="mt-2 bg-red-50 border-l-4 border-red-500 p-4">
                          <div className="flex items-center">
                            <FiAlertTriangle className="text-red-500 mr-3" />
                            <p className="text-sm text-red-700">{addError}</p>
                          </div>
                        </div>
                      )}

                      <div className="mt-4 space-y-4">
                        <div className="form-group">
                          <label htmlFor="email" className="form-label">
                            Email <span className="text-red-500">*</span>
                          </label>
                          <input
                            type="email"
                            id="email"
                            name="email"
                            value={newUser.email}
                            onChange={handleInputChange}
                            className="form-input"
                            required
                          />
                        </div>

                        <div className="form-group">
                          <label htmlFor="password" className="form-label">
                            Password <span className="text-red-500">*</span>
                          </label>
                          <input
                            type="password"
                            id="password"
                            name="password"
                            value={newUser.password}
                            onChange={handleInputChange}
                            className="form-input"
                            required
                          />
                        </div>

                        <div className="form-group">
                          <label htmlFor="role" className="form-label">
                            Role
                          </label>
                          <select
                            id="role"
                            name="role"
                            value={newUser.role}
                            onChange={handleInputChange}
                            className="form-input"
                          >
                            <option value="customer">Customer</option>
                            <option value="admin">Admin</option>
                          </select>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                  <button
                    type="submit"
                    className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-primary text-base font-medium text-dark hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary sm:ml-3 sm:w-auto sm:text-sm"
                    disabled={addLoading}
                  >
                    {addLoading ? (
                      <div className="flex items-center">
                        <div className="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-dark mr-2"></div>
                        <span>Memproses...</span>
                      </div>
                    ) : (
                      "Tambah"
                    )}
                  </button>
                  <button
                    type="button"
                    className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
                    onClick={() => setShowAddModal(false)}
                    disabled={addLoading}
                  >
                    Batal
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Users;
