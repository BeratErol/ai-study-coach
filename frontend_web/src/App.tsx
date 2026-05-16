import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import LoginPage      from './pages/LoginPage'
import RegisterPage   from './pages/RegisterPage'
import DashboardPage  from './pages/DashboardPage'
import GelisimimPage  from './pages/GelisimimPage'
import DenemelorPage  from './pages/DenemelorPage'
import ProfilePage    from './pages/ProfilePage'
import OnboardingPage from './pages/onboarding/OnboardingPage'
import Layout         from './components/Layout'
import ProtectedRoute from './components/ProtectedRoute'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login"    element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />

        <Route
          path="/onboarding"
          element={
            <ProtectedRoute>
              <OnboardingPage />
            </ProtectedRoute>
          }
        />

        <Route
          element={
            <ProtectedRoute>
              <Layout />
            </ProtectedRoute>
          }
        >
          <Route path="/dashboard"  element={<DashboardPage />} />
          <Route path="/gelisimim"  element={<GelisimimPage />} />
          <Route path="/denemeler"  element={<DenemelorPage />} />
          <Route path="/profile"    element={<ProfilePage />} />
        </Route>

        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
